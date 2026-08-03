import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/env.dart";
import "../../../map_discovery/presentation/providers/place_detail_providers.dart";
import "../../../map_discovery/presentation/providers/place_providers.dart";
import "../../data/datasources/favorite_remote_data_source.dart";
import "../../data/repositories/mock_favorite_repository.dart";
import "../../data/repositories/mock_visit_history_repository.dart";
import "../../data/repositories/rest_favorite_repository.dart";
import "../../data/repositories/rest_visit_history_repository.dart";
import "../../domain/entities/visit.dart";
import "../../domain/repositories/favorite_repository.dart";
import "../../domain/repositories/visit_history_repository.dart";

final Provider<FavoriteRemoteDataSource> favoriteRemoteDataSourceProvider =
    Provider<FavoriteRemoteDataSource>(
      (ref) => FavoriteRemoteDataSource(
        ref.watch(httpClientProvider),
        baseUrl: AppEnv.apiBaseUrl,
      ),
    );

/// A single shared mock instance for the app's lifetime — same reasoning
/// `_mockAuthRepositoryProvider` already applies (add/remove/toggle
/// mutate in-memory state a fresh instance per read would lose).
final Provider<MockFavoriteRepository> _mockFavoriteRepositoryProvider =
    Provider<MockFavoriteRepository>((ref) => MockFavoriteRepository());

/// The swap point for SCR-026's data (US-05.4).
final Provider<FavoriteRepository> favoriteRepositoryProvider =
    Provider<FavoriteRepository>((ref) {
      if (AppEnv.useMockAuth) {
        return ref.watch(_mockFavoriteRepositoryProvider);
      }
      return RestFavoriteRepository(
        ref.watch(favoriteRemoteDataSourceProvider),
        ref.watch(placeDetailRepositoryProvider),
      );
    });

/// The swap point for SCR-021's data (US-05.2). Always resolves to
/// [MockVisitHistoryRepository] when mocking is on, and always to
/// [RestVisitHistoryRepository] (which always throws
/// `VisitHistoryEndpointNotSpecifiedFailure`) otherwise — there is no
/// real endpoint to fall back to even once a backend exists, see that
/// failure's own doc comment.
final Provider<VisitHistoryRepository> visitHistoryRepositoryProvider =
    Provider<VisitHistoryRepository>((ref) {
      if (AppEnv.useMockAuth) {
        return const MockVisitHistoryRepository();
      }
      return const RestVisitHistoryRepository();
    });

/// SCR-021's data — `.autoDispose`, same reasoning `currentUserProvider`
/// already applies (only needs to be alive while the screen is open).
final visitHistoryProvider = FutureProvider.autoDispose<List<Visit>>(
  (ref) => ref.watch(visitHistoryRepositoryProvider).getVisitHistory(),
);
