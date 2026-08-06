import "../../domain/entities/visit.dart";
import "../../domain/repositories/visit_history_repository.dart";
import "../datasources/visit_history_remote_data_source.dart";

/// [VisitHistoryRepository] implementation backed by the REST API — calls
/// the real `GET /users/me/visit-history` endpoint (docs/api/openapi.yaml).
class RestVisitHistoryRepository implements VisitHistoryRepository {
  const RestVisitHistoryRepository(this._remote);

  final VisitHistoryRemoteDataSource _remote;

  @override
  Future<List<Visit>> getVisitHistory() async {
    final dtos = await _remote.getVisitHistory();
    return dtos.map((dto) => dto.toEntity()).toList();
  }
}
