import "../../domain/entities/access_session.dart";
import "../../domain/entities/access_session_status.dart";
import "../../domain/entities/money.dart";
import "../../domain/gateways/payment_gateway.dart";
import "../../domain/repositories/payment_repository.dart";

/// **Explicitly-opt-in mock adapter** for [PaymentRepository] — not wired
/// by default (see `AppEnv.useMockPayment`). Orchestrates
/// [PaymentGateway] (`MockPaymentGatewayAdapter`, ADR-0014's mandated
/// mock) directly — authorize → capture — simulating locally what
/// `docs/architecture/sequence-diagrams.md` §1 shows the *backend* doing,
/// since no backend exists yet (ADR-0016 still open) to actually do it.
///
/// Every value returned is fabricated, same discipline as
/// `MockPlaceDetailRepository` — this class's name and this doc comment
/// are the markers. [PaymentDeclinedFailure] is surfaced whenever the
/// underlying [PaymentGateway.authorize] call reports a decline, so
/// SCR-018's decline variant is genuinely reachable through this mock,
/// not merely documented.
class MockPaymentRepository implements PaymentRepository {
  const MockPaymentRepository(this._gateway);

  final PaymentGateway _gateway;

  @override
  Future<AccessSession> requestPayment({
    required String accessSessionId,
    required String? paymentMethodId,
    required bool applyEmergencyDiscount,
    required String idempotencyKey,
  }) async {
    const Money amount = Money(amount: "50", currency: "DZD");

    final AuthorizationResult authResult = await _gateway.authorize(
      amount: amount,
      // Free-cabin path (no saved method needed) — `PaymentGateway.authorize`
      // still requires a ref to simulate against; a fixed sentinel is fine
      // since a free authorization is never actually charged.
      paymentMethodRef: paymentMethodId ?? "free-access",
      idempotencyKey: idempotencyKey,
    );
    if (!authResult.approved) {
      throw PaymentDeclinedFailure(
        "Mock gateway declined authorization ${authResult.authorizationId}.",
      );
    }

    await _gateway.capture(authorizationId: authResult.authorizationId);

    final DateTime now = DateTime.now();
    return AccessSession(
      id: accessSessionId,
      cabinId: "mock-cabin-1",
      status: AccessSessionStatus.unlocked,
      startedAt: now,
      unlockedAt: now,
    );
  }
}
