import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/env.dart";
import "../../../map_discovery/presentation/providers/place_providers.dart";
import "../../data/datasources/access_session_remote_data_source.dart";
import "../../data/repositories/rest_access_session_repository.dart";
import "../../domain/entities/access_session.dart";
import "../../domain/repositories/access_session_repository.dart";
import "../../domain/usecases/initiate_access_session.dart";

/// DI wiring, mirroring `slatoki_place_providers.dart`'s composition-root
/// pattern — reuses [httpClientProvider] (map_discovery) rather than
/// creating a second `http.Client`. `access_payment` reading a
/// map_discovery-owned infra provider is fine (shared app-wide utility,
/// not a domain-layer dependency); `access_payment`'s own domain layer
/// still never imports from `map_discovery`.
final Provider<AccessSessionRemoteDataSource>
accessSessionRemoteDataSourceProvider = Provider<AccessSessionRemoteDataSource>(
  (ref) => AccessSessionRemoteDataSource(
    ref.watch(httpClientProvider),
    baseUrl: AppEnv.apiBaseUrl,
  ),
);

final Provider<AccessSessionRepository> accessSessionRepositoryProvider =
    Provider<AccessSessionRepository>(
      (ref) => RestAccessSessionRepository(
        ref.watch(accessSessionRemoteDataSourceProvider),
      ),
    );

final Provider<InitiateAccessSession> initiateAccessSessionProvider =
    Provider<InitiateAccessSession>(
      (ref) =>
          InitiateAccessSession(ref.watch(accessSessionRepositoryProvider)),
    );

/// One-shot submission state for SCR-013 — `null` before any attempt,
/// [AsyncLoading] while [InitiateAccessSession] is in flight, [AsyncError]
/// on [InvalidQrCodeFailure]/[AccessSessionRepositoryFailure] (checked via
/// `error is` in the presentation layer, not parsed from a message
/// string), [AsyncData] with the created [AccessSession] on success.
class QrScanNotifier extends AsyncNotifier<AccessSession?> {
  @override
  AccessSession? build() => null;

  Future<void> submit(String rawValue) async {
    state = const AsyncLoading<AccessSession?>();
    final InitiateAccessSession useCase = ref.read(
      initiateAccessSessionProvider,
    );
    state = await AsyncValue.guard(() => useCase(rawValue: rawValue));
  }

  /// Clears a terminal ([AsyncError]) state so the scanner can accept
  /// another attempt without navigating away from SCR-013.
  void reset() => state = const AsyncData<AccessSession?>(null);
}

final AsyncNotifierProvider<QrScanNotifier, AccessSession?>
qrScanNotifierProvider = AsyncNotifierProvider<QrScanNotifier, AccessSession?>(
  QrScanNotifier.new,
);
