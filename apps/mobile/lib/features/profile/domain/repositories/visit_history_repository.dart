import "../entities/visit.dart";

sealed class VisitHistoryRepositoryFailure implements Exception {
  const VisitHistoryRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class VisitHistoryApiNotConfiguredFailure
    extends VisitHistoryRepositoryFailure {
  const VisitHistoryApiNotConfiguredFailure()
    : super("No backend API is configured for this build.");
}

/// **API contract gap** — docs/api/openapi.yaml has no endpoint for
/// listing a user's past access sessions/visits (only
/// `POST /access-sessions` and `GET /access-sessions/{id}` by a single
/// known id exist). [RestVisitHistoryRepository] always throws this,
/// distinct from [VisitHistoryApiNotConfiguredFailure] ("would work if a
/// backend were deployed") — this failure means "would not work even
/// against a deployed backend, because the endpoint isn't specified."
/// Flagged in `docs/phase-3-implementation-log.md`'s API Contract Gaps
/// section rather than invented (see Feature 19's Architecture Notes) —
/// the natural shape would be `GET /users/me/access-sessions` or
/// `GET /users/me/visits`, mirroring the `/users/me/favorites` pattern.
class VisitHistoryEndpointNotSpecifiedFailure
    extends VisitHistoryRepositoryFailure {
  const VisitHistoryEndpointNotSpecifiedFailure()
    : super(
        "No endpoint is specified in docs/api/openapi.yaml for listing "
        "visit history.",
      );
}

class VisitHistoryRequestFailure extends VisitHistoryRepositoryFailure {
  const VisitHistoryRequestFailure(super.message);
}

/// Repository port for SCR-021 (Visit History, US-05.2).
abstract interface class VisitHistoryRepository {
  Future<List<Visit>> getVisitHistory();
}
