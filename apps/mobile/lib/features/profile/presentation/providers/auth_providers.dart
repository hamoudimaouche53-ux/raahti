import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/env.dart";
import "../../../../core/providers/supabase_provider.dart";
import "../../../map_discovery/presentation/providers/place_providers.dart";
import "../../data/datasources/user_remote_data_source.dart";
import "../../data/repositories/mock_auth_repository.dart";
import "../../data/repositories/mock_user_repository.dart";
import "../../data/repositories/rest_user_repository.dart";
import "../../data/repositories/supabase_auth_repository.dart";
import "../../domain/entities/app_user.dart";
import "../../domain/repositories/auth_repository.dart";
import "../../domain/repositories/user_repository.dart";

/// Never authenticated — the fallback when neither a real Supabase
/// project ([AppEnv.isSupabaseConfigured]) nor the mock opt-in
/// ([AppEnv.useMockAuth]) is configured. Mirrors
/// `_UnavailableCabinRealtimeRepository`'s three-way swap pattern
/// (Feature 17) — see [AuthNotConfiguredFailure]'s own doc comment for
/// why this needs a genuine "unavailable" branch rather than reusing the
/// two-way mock/REST pattern most other repositories use.
class _UnavailableAuthRepository implements AuthRepository {
  const _UnavailableAuthRepository();

  @override
  Stream<String?> watchCurrentUserId() => Stream.value(null);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) => throw const AuthNotConfiguredFailure();

  @override
  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) => throw const AuthNotConfiguredFailure();

  @override
  Future<void> signOut() async {}
}

/// A single shared mock instance for the app's lifetime — same reasoning
/// `MockPaymentMethodRepository`'s wiring already applies (its
/// `addPaymentMethod`/here, `signInWithPassword` mutate in-memory state a
/// fresh instance per read would lose).
final Provider<MockAuthRepository> _mockAuthRepositoryProvider =
    Provider<MockAuthRepository>((ref) => MockAuthRepository());

/// The swap point for authentication (US-05.1, ADR-0009).
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) {
      if (AppEnv.useMockAuth) {
        return ref.watch(_mockAuthRepositoryProvider);
      }
      if (AppEnv.isSupabaseConfigured) {
        return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
      }
      return const _UnavailableAuthRepository();
    });

/// The current Supabase Auth user id, or `null` for a guest — the single
/// source of truth every EPIC-05 screen reads to decide guest vs.
/// registered state (SCR-020's own wireframe: "guest (locked sections
/// visible-but-disabled)... registered").
final StreamProvider<String?> currentUserIdProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).watchCurrentUserId(),
);

final Provider<UserRemoteDataSource> userRemoteDataSourceProvider =
    Provider<UserRemoteDataSource>(
      (ref) => UserRemoteDataSource(
        ref.watch(httpClientProvider),
        baseUrl: AppEnv.apiBaseUrl,
      ),
    );

final Provider<UserRepository> userRepositoryProvider =
    Provider<UserRepository>((ref) {
      if (AppEnv.useMockAuth) {
        return const MockUserRepository();
      }
      return RestUserRepository(ref.watch(userRemoteDataSourceProvider));
    });

/// The signed-in account's RAHATI profile (SCR-020's account summary card)
/// — `null` for a guest, re-fetched whenever [currentUserIdProvider]
/// changes. `.autoDispose` — like `cabinOccupancyUpdatesProvider`
/// (Feature 17), this only needs to be alive while a Profile-area screen
/// is on screen, not for the app's whole lifetime. No explicit provider
/// type annotation — same reasoning `cabinOccupancyUpdatesProvider`'s own
/// doc comment gives (the generated `AutoDisposeFutureProvider` type
/// isn't part of `flutter_riverpod`'s public API surface in this
/// version).
final currentUserProvider = FutureProvider.autoDispose<AppUser?>((ref) async {
  final AsyncValue<String?> userId = ref.watch(currentUserIdProvider);
  final String? id = userId.value;
  if (id == null) return null;
  return ref.watch(userRepositoryProvider).getCurrentUser();
});
