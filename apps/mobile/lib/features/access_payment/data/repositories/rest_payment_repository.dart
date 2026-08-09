import "../../domain/entities/access_session.dart";
import "../../domain/repositories/payment_repository.dart";
import "../datasources/payment_remote_data_source.dart";

/// [PaymentRepository] implementation backed by the REST API. No
/// offline-queue fallback (ADR-0008) — same rationale as
/// `RestAccessSessionRepository`.
class RestPaymentRepository implements PaymentRepository {
  const RestPaymentRepository(this._remote);

  final PaymentRemoteDataSource _remote;

  @override
  Future<AccessSession> requestPayment({
    required String accessSessionId,
    required String? paymentMethodId,
    required bool applyEmergencyDiscount,
    required String idempotencyKey,
  }) async {
    final dto = await _remote.requestPayment(
      accessSessionId: accessSessionId,
      paymentMethodId: paymentMethodId,
      applyEmergencyDiscount: applyEmergencyDiscount,
      idempotencyKey: idempotencyKey,
    );
    return dto.accessSession.toEntity();
  }
}
