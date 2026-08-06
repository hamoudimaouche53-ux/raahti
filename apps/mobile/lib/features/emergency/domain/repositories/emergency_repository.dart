import "../../../map_discovery/domain/entities/coordinates.dart";
import "../entities/emergency_facility_result.dart";

/// Domain-owned failure hierarchy — same discipline as
/// `AccessSessionRepositoryFailure`: scoped to this bounded context, not an
/// HTTP status or Data-layer exception. A "no facility found" 404 is
/// deliberately **not** modeled here — see [EmergencyRepository]'s own doc
/// comment for why that's an expected `null` result, not a failure.
sealed class EmergencyRepositoryFailure implements Exception {
  const EmergencyRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// No backend API base URL is configured for this build — same rationale
/// as `AccessPaymentApiNotConfiguredFailure`.
class EmergencyApiNotConfiguredFailure extends EmergencyRepositoryFailure {
  const EmergencyApiNotConfiguredFailure()
    : super("No backend API is configured for this build.");
}

/// The API call was attempted but failed for any other reason (network
/// unreachable, `401` unauthorized, non-2xx/404 response, malformed
/// payload).
class EmergencyRequestFailure extends EmergencyRepositoryFailure {
  const EmergencyRequestFailure(super.message);
}

/// Repository port for `GET /emergency/nearest-facility` (US-03.1/03.2,
/// FR-EMG-01/02). Implemented by the Data layer
/// (`RestEmergencyRepository`); Domain and Presentation depend only on
/// this interface.
abstract interface class EmergencyRepository {
  /// Returns `null` for the backend's `404` response — "no accessible
  /// facility found nearby" is an expected, valid outcome (SCR-011's
  /// no-facility-found state), not a genuine failure. Mirrors how
  /// `AccessSessionRepository`'s failure hierarchy separates expected
  /// empty results from actual errors. Throws an
  /// [EmergencyRepositoryFailure] subtype for any other failure.
  Future<EmergencyFacilityResult?> findNearestFacility({
    required Coordinates position,
  });
}
