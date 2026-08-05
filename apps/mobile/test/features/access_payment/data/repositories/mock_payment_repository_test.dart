import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/data/adapters/mock_payment_gateway_adapter.dart";
import "package:rahati/features/access_payment/data/repositories/mock_payment_repository.dart";
import "package:rahati/features/access_payment/domain/entities/access_session_status.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_repository.dart";

void main() {
  group("MockPaymentRepository", () {
    test("approves by default and returns an unlocked AccessSession", () async {
      final repository = MockPaymentRepository(
        MockPaymentGatewayAdapter(simulatedLatency: Duration.zero),
      );

      final result = await repository.requestPayment(
        accessSessionId: "session-1",
        paymentMethodId: "pm-1",
        applyEmergencyDiscount: false,
        idempotencyKey: "key-1",
      );

      expect(result.id, "session-1");
      expect(result.status, AccessSessionStatus.unlocked);
      expect(result.unlockedAt, isNotNull);
    });

    test("throws PaymentDeclinedFailure when the underlying gateway declines "
        "authorization", () async {
      final repository = MockPaymentRepository(
        MockPaymentGatewayAdapter(
          simulatedLatency: Duration.zero,
          declineAuthorization: true,
        ),
      );

      expect(
        () => repository.requestPayment(
          accessSessionId: "session-1",
          paymentMethodId: "pm-1",
          applyEmergencyDiscount: false,
          idempotencyKey: "key-1",
        ),
        throwsA(isA<PaymentDeclinedFailure>()),
      );
    });
  });
}
