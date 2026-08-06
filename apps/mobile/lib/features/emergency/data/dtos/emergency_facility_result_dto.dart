import "../../../map_discovery/data/dtos/place_dto.dart";
import "../../../map_discovery/domain/entities/place.dart";
import "../../domain/entities/emergency_facility_result.dart";

/// JSON mapping for the `EmergencyFacilityResult` schema in
/// docs/api/openapi.yaml — the response body of
/// `GET /emergency/nearest-facility`. The only layer allowed to know this
/// wire format — the Domain layer sees only [EmergencyFacilityResult].
class EmergencyFacilityResultDto {
  const EmergencyFacilityResultDto({
    required this.place,
    required this.nearestCabinId,
    required this.discountEligible,
  });

  factory EmergencyFacilityResultDto.fromJson(Map<String, dynamic> json) {
    return EmergencyFacilityResultDto(
      place: PlaceDto.fromJson(json["place"] as Map<String, dynamic>),
      nearestCabinId: json["nearestCabinId"] as String?,
      discountEligible: json["discountEligible"] as bool,
    );
  }

  final PlaceDto place;
  final String? nearestCabinId;
  final bool discountEligible;

  /// ~5 km/h average walking speed, in meters/minute — a flagged
  /// client-side judgment call (see
  /// [EmergencyFacilityResult.etaMinutesOnFoot]'s doc comment): the
  /// backend contract has no ETA field at all, and SCR-011's wireframe
  /// documents no formula for its "X min à pied" line.
  static const double _walkingSpeedMetersPerMinute = 83.3;

  EmergencyFacilityResult toEntity() {
    final Place resolvedPlace = place.toEntity();
    return EmergencyFacilityResult(
      place: resolvedPlace,
      nearestCabinId: nearestCabinId,
      discountEligible: discountEligible,
      etaMinutesOnFoot:
          (resolvedPlace.distanceMeters / _walkingSpeedMetersPerMinute).round(),
    );
  }
}
