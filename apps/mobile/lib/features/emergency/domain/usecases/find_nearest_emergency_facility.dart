import "../../../map_discovery/domain/entities/coordinates.dart";
import "../entities/emergency_facility_result.dart";
import "../repositories/emergency_repository.dart";

/// Application-layer use case for FR-EMG-01/02 (US-03.1) — thin wrapper
/// around [EmergencyRepository], mirroring [InitiateAccessSession]'s
/// single-`call()`-method style. Unlike
/// `InitiateAccessSession`/`RequestPayment`, this call is read-only, so
/// there is no idempotency key to attach.
class FindNearestEmergencyFacility {
  const FindNearestEmergencyFacility(this._repository);

  final EmergencyRepository _repository;

  Future<EmergencyFacilityResult?> call({required Coordinates position}) {
    return _repository.findNearestFacility(position: position);
  }
}
