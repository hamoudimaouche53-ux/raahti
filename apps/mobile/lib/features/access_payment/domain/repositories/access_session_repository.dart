import "../entities/access_session.dart";
import "../entities/qr_code.dart";

/// Domain-owned failure hierarchy — same discipline as
/// `SlatokiPlaceRepositoryFailure`: scoped to this bounded context, not an
/// HTTP status or Data-layer exception.
sealed class AccessSessionRepositoryFailure implements Exception {
  const AccessSessionRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No backend API base URL is configured for this build — expected until
/// ADR-0016's hosting decision lands and a backend is deployed (the
/// `access-payment` backend module is scaffold-only as of this epic).
class AccessPaymentApiNotConfiguredFailure
    extends AccessSessionRepositoryFailure {
  const AccessPaymentApiNotConfiguredFailure()
    : super("No backend API is configured for this build.");
}

/// `POST /access-sessions` returned 409 — the cabin identified by the
/// scanned QR code is no longer available (FR-PAY-02, SCR-014's
/// unavailable state).
class CabinUnavailableFailure extends AccessSessionRepositoryFailure {
  const CabinUnavailableFailure() : super("This cabin is no longer available.");
}

/// The API call was attempted but failed for any other reason (network
/// unreachable, non-2xx/409 response, malformed payload).
class AccessSessionRequestFailure extends AccessSessionRepositoryFailure {
  const AccessSessionRequestFailure(super.message);
}

/// Repository port for `POST /access-sessions` (US-04.1, FR-PAY-01) and
/// `GET /access-sessions/{id}` (US-04.5's documented polling fallback,
/// docs/api/openapi.yaml). Implemented by the Data layer
/// (`RestAccessSessionRepository`); Domain and Presentation depend only on
/// this interface.
///
/// Availability (US-04.2, FR-PAY-02) is deliberately not a separate method
/// — per docs/architecture/sequence-diagrams.md §1, the backend resolves
/// it synchronously inside the same `POST /access-sessions` call.
abstract interface class AccessSessionRepository {
  /// Per ADR-0008, this call is strictly online — never queued in the
  /// local offline write-queue. Throws [AccessSessionRepositoryFailure] on
  /// any failure, including [CabinUnavailableFailure] for a 409 response.
  Future<AccessSession> initiateAccessSession({
    required QrCode qrCodeScanned,
    required String idempotencyKey,
  });

  /// Fallback channel only — the primary channel for status updates is the
  /// Realtime subscription (US-04.5).
  Future<AccessSession> getAccessSession(String accessSessionId);

  /// `POST /access-sessions/{id}/complete` (SCR-019's "J'ai terminé"
  /// manual-completion path, US-04.6/ADR-0026 Decision 2 — no invented
  /// auto-close, this is the app's own explicit action). Doubles
  /// server-side as the simulated door-sensor-close event until Phase 9
  /// IoT ships real hardware (ADR-0030).
  Future<AccessSession> completeAccessSession(String accessSessionId);
}
