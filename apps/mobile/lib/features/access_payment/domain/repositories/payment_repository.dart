import "../entities/access_session.dart";

sealed class PaymentRepositoryFailure implements Exception {
  const PaymentRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No backend API base URL is configured for this build (see
/// [AccessPaymentApiNotConfiguredFailure]'s counterpart doc comment).
class PaymentApiNotConfiguredFailure extends PaymentRepositoryFailure {
  const PaymentApiNotConfiguredFailure()
    : super("No backend API is configured for this build.");
}

/// `POST /access-sessions/{id}/payments` returned 402 — the payment
/// provider declined the authorization/capture (SCR-018's decline
/// variant). The user may retry with a different payment method
/// (re-opens SCR-015), per docs/design/wireframes/mobile-emergency-payment.md.
class PaymentDeclinedFailure extends PaymentRepositoryFailure {
  const PaymentDeclinedFailure(super.message);
}

/// `POST /access-sessions/{id}/payments` returned 502
/// `ProblemDetail{code: UNLOCK_FAILED_REFUNDED}` — payment was captured
/// but the unlock order failed (Risk R-12), and the backend has already
/// issued a refund via `PaymentGateway.refund` (ADR-0014). SCR-018's
/// unlock-failure variant routes back to SCR-013 on retry — re-scanning is
/// required, not a naive payment retry, since the cabin's state must be
/// re-verified.
class UnlockFailedRefundedFailure extends PaymentRepositoryFailure {
  const UnlockFailedRefundedFailure(super.message);
}

/// The API call was attempted but failed for any other reason.
class PaymentRequestFailure extends PaymentRepositoryFailure {
  const PaymentRequestFailure(super.message);
}

/// Repository port for `POST /access-sessions/{id}/payments`
/// (US-04.3/US-04.4, FR-PAY-03/04). A single call: per
/// docs/architecture/sequence-diagrams.md §1, the backend orchestrates
/// authorize → capture → unlock-order issuance → wait-for-ack within this
/// one request/response — there is no separate "unlock request" call from
/// the mobile app.
///
/// Only invoked for paid cabins — a free cabin's `AccessSession` reaches
/// `AccessSessionStatus.unlocked` directly from `POST /access-sessions`,
/// skipping SCR-015/016 entirely per the approved user flow.
abstract interface class PaymentRepository {
  /// [paymentMethodId] identifies a saved payment method (SCR-015).
  /// [applyEmergencyDiscount] is accepted for forward-compatibility with
  /// EPIC-03's Mode Urgence discount (see `DiscountRate`'s doc comment) —
  /// this epic never sets it `true`.
  ///
  /// Per ADR-0026 Decision 1, the caller (not this port) is responsible
  /// for bounding how long it waits on this call — this method itself
  /// simply awaits the backend's response, however long that takes.
  Future<AccessSession> requestPayment({
    required String accessSessionId,
    required String paymentMethodId,
    required bool applyEmergencyDiscount,
    required String idempotencyKey,
  });
}
