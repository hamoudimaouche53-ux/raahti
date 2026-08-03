import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/data/adapters/mock_payment_gateway_adapter.dart";
import "package:rahati/features/access_payment/domain/entities/money.dart";

void main() {
  const amount = Money(amount: "50", currency: "DZD");

  group("MockPaymentGatewayAdapter.authorize", () {
    test("approves by default", () async {
      final adapter = MockPaymentGatewayAdapter(
        simulatedLatency: Duration.zero,
      );
      final result = await adapter.authorize(
        amount: amount,
        paymentMethodRef: "pm-1",
        idempotencyKey: "key-1",
      );
      expect(result.approved, isTrue);
      expect(result.authorizationId, isNotEmpty);
    });

    test(
      "declines when declineAuthorization is true (drives SCR-018)",
      () async {
        final adapter = MockPaymentGatewayAdapter(
          simulatedLatency: Duration.zero,
          declineAuthorization: true,
        );
        final result = await adapter.authorize(
          amount: amount,
          paymentMethodRef: "pm-1",
          idempotencyKey: "key-1",
        );
        expect(result.approved, isFalse);
      },
    );
  });

  group("MockPaymentGatewayAdapter.capture", () {
    test("returns a captureId and providerRef", () async {
      final adapter = MockPaymentGatewayAdapter(
        simulatedLatency: Duration.zero,
      );
      final result = await adapter.capture(authorizationId: "auth-1");
      expect(result.captureId, isNotEmpty);
      expect(result.providerRef, isNotEmpty);
    });
  });

  group("MockPaymentGatewayAdapter.refund", () {
    test("succeeds by default (Risk R-12 mitigation)", () async {
      final adapter = MockPaymentGatewayAdapter(
        simulatedLatency: Duration.zero,
      );
      final result = await adapter.refund(
        captureId: "capture-1",
        amount: amount,
      );
      expect(result.succeeded, isTrue);
    });

    test("fails when failUnlockRefund is true", () async {
      final adapter = MockPaymentGatewayAdapter(
        simulatedLatency: Duration.zero,
        failUnlockRefund: true,
      );
      final result = await adapter.refund(
        captureId: "capture-1",
        amount: amount,
      );
      expect(result.succeeded, isFalse);
    });
  });

  group("MockPaymentGatewayAdapter.tokenizePaymentMethod", () {
    test("returns an opaque token, never the raw input", () async {
      final adapter = MockPaymentGatewayAdapter(
        simulatedLatency: Duration.zero,
      );
      final ref = await adapter.tokenizePaymentMethod(
        rawMethodToken: "4242424242424242",
      );
      expect(ref.value, isNot(contains("4242424242424242")));
    });
  });

  test("respects simulatedLatency", () async {
    final adapter = MockPaymentGatewayAdapter(
      simulatedLatency: const Duration(milliseconds: 50),
    );
    final stopwatch = Stopwatch()..start();
    await adapter.authorize(
      amount: amount,
      paymentMethodRef: "pm-1",
      idempotencyKey: "key-1",
    );
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(45));
  });
}
