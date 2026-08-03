import "../entities/money.dart";

/// Result of [PaymentGateway.authorize].
class AuthorizationResult {
  const AuthorizationResult({
    required this.authorizationId,
    required this.approved,
  });

  final String authorizationId;
  final bool approved;
}

/// Result of [PaymentGateway.capture].
class CaptureResult {
  const CaptureResult({required this.captureId, required this.providerRef});

  final String captureId;
  final String providerRef;
}

/// Result of [PaymentGateway.refund].
class RefundResult {
  const RefundResult({required this.refundId, required this.succeeded});

  final String refundId;
  final bool succeeded;
}

/// Result of [PaymentGateway.tokenizePaymentMethod] — an opaque,
/// provider-issued reference, never raw card/wallet data (ADR-0014).
class PaymentMethodRef {
  const PaymentMethodRef(this.value);

  final String value;
}

/// The Anti-Corruption Layer port isolating this app from any specific
/// payment provider — the exact interface decided in
/// docs/adr/0014-payment-provider-abstraction.md.
///
/// **No vendor SDK may be referenced anywhere except a single, future
/// `<Provider>PaymentGatewayAdapter` class implementing this interface.**
/// Until a provider is selected, [MockPaymentGatewayAdapter]
/// (`data/adapters/mock_payment_gateway_adapter.dart`) is the only
/// implementation — mandated by ADR-0014 for this phase, not a
/// workaround.
///
/// All application-layer use cases in this feature depend only on this
/// interface (Dependency Inversion) — never on a concrete adapter type.
abstract interface class PaymentGateway {
  Future<AuthorizationResult> authorize({
    required Money amount,
    required String paymentMethodRef,
    required String idempotencyKey,
  });

  Future<CaptureResult> capture({required String authorizationId});

  Future<RefundResult> refund({
    required String captureId,
    required Money amount,
  });

  Future<PaymentMethodRef> tokenizePaymentMethod({
    required String rawMethodToken,
  });
}
