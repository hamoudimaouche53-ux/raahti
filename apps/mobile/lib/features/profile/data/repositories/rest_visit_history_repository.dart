import "../../domain/entities/visit.dart";
import "../../domain/repositories/visit_history_repository.dart";

/// [VisitHistoryRepository] implementation backed by the REST API — always
/// throws [VisitHistoryEndpointNotSpecifiedFailure]; see that failure's own
/// doc comment for why (no listing endpoint exists in
/// docs/api/openapi.yaml).
class RestVisitHistoryRepository implements VisitHistoryRepository {
  const RestVisitHistoryRepository();

  @override
  Future<List<Visit>> getVisitHistory() async {
    throw const VisitHistoryEndpointNotSpecifiedFailure();
  }
}
