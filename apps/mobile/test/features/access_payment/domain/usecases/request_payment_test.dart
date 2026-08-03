import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/domain/entities/access_session.dart";
import "package:rahati/features/access_payment/domain/entities/access_session_status.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_repository.dart";
import "package:rahati/features/access_payment/domain/usecases/request_payment.dart";

class _FakePaymentRepository implements PaymentRepository {
  _FakePaymentRepository({this.failure});

  final PaymentRepositoryFailure? failure;
  int callCount = 0;
  String? lastAccessSessionId;
  String? lastPaymentMethodId;
  String? lastIdempotencyKey;

  @override
  Future<AccessSession> requestPayment({
    required String accessSessionId,
    required String paymentMethodId,
    required bool applyEmergencyDiscount,
    required String idempotencyKey,
  }) async {
    callCount++;
    lastAccessSessionId = accessSessionId;
    lastPaymentMethodId = paymentMethodId;
    lastIdempotencyKey = idempotencyKey;
    final PaymentRepositoryFailure? f = failure;
    if (f != null) throw f;
    return AccessSession(
      id: accessSessionId,
      cabinId: "cabin-1",
      status: AccessSessionStatus.unlocked,
      startedAt: DateTime(2026),
      unlockedAt: DateTime(2026),
    );
  }
}

void main() {
  group("RequestPayment", () {
    test("attaches a freshly generated Idempotency-Key", () async {
      final repository = _FakePaymentRepository();
      final useCase = RequestPayment(repository);

      final AccessSession result = await useCase(
        accessSessionId: "session-1",
        paymentMethodId: "pm-1",
      );

      expect(result.id, "session-1");
      expect(repository.callCount, 1);
      expect(repository.lastAccessSessionId, "session-1");
      expect(repository.lastPaymentMethodId, "pm-1");
      expect(repository.lastIdempotencyKey, isNotEmpty);
    });

    test("generates a different Idempotency-Key per call", () async {
      final repository = _FakePaymentRepository();
      final useCase = RequestPayment(repository);

      await useCase(accessSessionId: "session-1", paymentMethodId: "pm-1");
      final String? firstKey = repository.lastIdempotencyKey;
      await useCase(accessSessionId: "session-1", paymentMethodId: "pm-1");
      final String? secondKey = repository.lastIdempotencyKey;

      expect(firstKey, isNot(equals(secondKey)));
    });

    test(
      "propagates a repository failure (e.g. PaymentDeclinedFailure)",
      () async {
        final repository = _FakePaymentRepository(
          failure: const PaymentDeclinedFailure("declined"),
        );
        final useCase = RequestPayment(repository);

        await expectLater(
          () => useCase(accessSessionId: "session-1", paymentMethodId: "pm-1"),
          throwsA(isA<PaymentDeclinedFailure>()),
        );
      },
    );
  });
}
