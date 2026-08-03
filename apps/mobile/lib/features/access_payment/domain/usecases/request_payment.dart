import "../entities/access_session.dart";
import "../repositories/payment_repository.dart";
import "../services/idempotency_key_generator.dart";

/// Application-layer use case for FR-PAY-03/04 (US-04.3) — attaches a
/// fresh `Idempotency-Key` and calls [PaymentRepository] exactly once,
/// same shape as [InitiateAccessSession].
class RequestPayment {
  const RequestPayment(
    this._repository, {
    this._idempotencyKeyGenerator = const IdempotencyKeyGenerator(),
  });

  final PaymentRepository _repository;
  final IdempotencyKeyGenerator _idempotencyKeyGenerator;

  Future<AccessSession> call({
    required String accessSessionId,
    required String paymentMethodId,
    bool applyEmergencyDiscount = false,
  }) {
    final String idempotencyKey = _idempotencyKeyGenerator.generate();
    return _repository.requestPayment(
      accessSessionId: accessSessionId,
      paymentMethodId: paymentMethodId,
      applyEmergencyDiscount: applyEmergencyDiscount,
      idempotencyKey: idempotencyKey,
    );
  }
}
