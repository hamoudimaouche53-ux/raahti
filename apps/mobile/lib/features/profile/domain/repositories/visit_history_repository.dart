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

/// **Historical** — `GET /users/me/visit-history` is now specified in
/// docs/api/openapi.yaml and implemented by [RestVisitHistoryRepository].
/// Kept only for any lingering references; no longer thrown by this
/// codebase.
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
