import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/env.dart";
import "../../../map_discovery/presentation/providers/place_providers.dart";
import "../../data/datasources/visit_history_remote_data_source.dart";
import "../../data/repositories/mock_visit_history_repository.dart";
import "../../data/repositories/rest_visit_history_repository.dart";
import "../../domain/entities/visit.dart";
import "../../domain/repositories/visit_history_repository.dart";

final Provider<VisitHistoryRemoteDataSource>
visitHistoryRemoteDataSourceProvider = Provider<VisitHistoryRemoteDataSource>(
  (ref) => VisitHistoryRemoteDataSource(
    ref.watch(httpClientProvider),
    baseUrl: AppEnv.apiBaseUrl,
  ),
);

/// The swap point for SCR-021's data (US-05.2). Resolves to
/// [MockVisitHistoryRepository] when mocking is on, and to
/// [RestVisitHistoryRepository] (backed by the real
/// `GET /users/me/visit-history` endpoint) otherwise.
final Provider<VisitHistoryRepository> visitHistoryRepositoryProvider =
    Provider<VisitHistoryRepository>((ref) {
      if (AppEnv.useMockAuth) {
        return const MockVisitHistoryRepository();
      }
      return RestVisitHistoryRepository(
        ref.watch(visitHistoryRemoteDataSourceProvider),
      );
    });

/// SCR-021's data — `.autoDispose`, same reasoning `currentUserProvider`
/// already applies (only needs to be alive while the screen is open).
final visitHistoryProvider = FutureProvider.autoDispose<List<Visit>>(
  (ref) => ref.watch(visitHistoryRepositoryProvider).getVisitHistory(),
);
