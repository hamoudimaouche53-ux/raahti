import "dart:math";

import "../../domain/entities/money.dart";
import "../../domain/gateways/payment_gateway.dart";

/// The **only** [PaymentGateway] implementation permitted until a real
/// payment provider is selected — mandated by ADR-0014, not an improvised
/// workaround: "A `MockPaymentGatewayAdapter` (deterministic, in-memory)
/// is used for all Phase 1–era development, testing, and demo
/// environments until a provider is approved."
///
/// Deterministic and configurable (not hidden randomness) so both the
/// success and failure paths this epic's screens depend on (SCR-016 →
/// SCR-017 vs. SCR-016 → SCR-018) are reliably testable. Every value
/// returned is a fabricated, clearly-labeled placeholder — this class's
/// name and this doc comment are the markers, matching the discipline
/// `MockPlaceDetailRepository` established for `map_discovery` (ADR-0023).
///
/// When a provider is selected, only a new `<Provider>PaymentGatewayAdapter`
/// Infrastructure-layer class is needed — zero changes to the domain or
/// presentation layers that depend on [PaymentGateway] (ADR-0014's whole
/// point).
class MockPaymentGatewayAdapter implements PaymentGateway {
  MockPaymentGatewayAdapter({
    this.simulatedLatency = const Duration(milliseconds: 600),
    this.declineAuthorization = false,
    this.failUnlockRefund = false,
    Random? random,
  }) : _random = random ?? Random();

  /// An artificial delay so SCR-016's processing state is genuinely
  /// demonstrable rather than resolving suspiciously instantly.
  final Duration simulatedLatency;

  /// When `true`, [authorize] reports a declined authorization — drives
  /// SCR-018's payment-decline variant in tests/demos.
  final bool declineAuthorization;

  /// When `true`, [refund] reports failure — an edge case surfaced only
  /// in tests, since a failed refund has no distinct UI state of its own
  /// per the approved wireframes (SCR-018's refund variant assumes the
  /// refund succeeds, per Risk R-12's mitigation).
  final bool failUnlockRefund;

  final Random _random;

  @override
  Future<AuthorizationResult> authorize({
    required Money amount,
    required String paymentMethodRef,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(simulatedLatency);
    return AuthorizationResult(
      authorizationId: "mock-auth-${_randomId()}",
      approved: !declineAuthorization,
    );
  }

  @override
  Future<CaptureResult> capture({required String authorizationId}) async {
    await Future<void>.delayed(simulatedLatency);
    return CaptureResult(
      captureId: "mock-capture-${_randomId()}",
      providerRef: "mock-provider-ref-${_randomId()}",
    );
  }

  @override
  Future<RefundResult> refund({
    required String captureId,
    required Money amount,
  }) async {
    await Future<void>.delayed(simulatedLatency);
    return RefundResult(
      refundId: "mock-refund-${_randomId()}",
      succeeded: !failUnlockRefund,
    );
  }

  @override
  Future<PaymentMethodRef> tokenizePaymentMethod({
    required String rawMethodToken,
  }) async {
    await Future<void>.delayed(simulatedLatency);
    return PaymentMethodRef("mock-token-${_randomId()}");
  }

  String _randomId() => _random.nextInt(1 << 32).toRadixString(16);
}
