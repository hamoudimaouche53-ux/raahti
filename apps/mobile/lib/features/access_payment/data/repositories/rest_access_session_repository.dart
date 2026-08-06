import "../../domain/entities/access_session.dart";
import "../../domain/entities/qr_code.dart";
import "../../domain/repositories/access_session_repository.dart";
import "../datasources/access_session_remote_data_source.dart";

/// [AccessSessionRepository] implementation backed by the REST API. No
/// offline-cache fallback — ADR-0008, same rationale as
/// `SlatokiPlaceRepository`'s interface doc comment.
class RestAccessSessionRepository implements AccessSessionRepository {
  const RestAccessSessionRepository(this._remote);

  final AccessSessionRemoteDataSource _remote;

  @override
  Future<AccessSession> initiateAccessSession({
    required QrCode qrCodeScanned,
    required String idempotencyKey,
  }) async {
    final dto = await _remote.initiateAccessSession(
      qrCodeScanned: qrCodeScanned.value,
      idempotencyKey: idempotencyKey,
    );
    return dto.toEntity();
  }

  @override
  Future<AccessSession> getAccessSession(String accessSessionId) async {
    final dto = await _remote.fetchAccessSession(accessSessionId);
    return dto.toEntity();
  }

  @override
  Future<AccessSession> completeAccessSession(String accessSessionId) async {
    final dto = await _remote.completeAccessSession(accessSessionId);
    return dto.toEntity();
  }
}
