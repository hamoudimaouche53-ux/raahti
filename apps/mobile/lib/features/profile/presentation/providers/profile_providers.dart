import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/constants/env.dart";
import "../../data/repositories/mock_visit_history_repository.dart";
import "../../data/repositories/rest_visit_history_repository.dart";
import "../../domain/entities/visit.dart";
import "../../domain/repositories/visit_history_repository.dart";

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
