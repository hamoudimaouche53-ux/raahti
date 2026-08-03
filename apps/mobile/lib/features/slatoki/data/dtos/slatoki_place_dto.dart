import "../../../map_discovery/data/dtos/place_dto.dart";
import "../../domain/entities/slatoki_place.dart";
import "../../domain/entities/women_verification_level.dart";

/// JSON mapping for `SlatokiPlaceSummary` (docs/api/openapi.yaml) — `allOf`
/// [PlaceSummary] + `womenVerificationLevel`. Delegates the base fields to
/// [PlaceDto] (already exactly `PlaceSummary`'s mapping) rather than
/// duplicating them.
class SlatokiPlaceDto {
  const SlatokiPlaceDto({
    required this.place,
    required this.womenVerificationLevel,
  });

  factory SlatokiPlaceDto.fromJson(Map<String, dynamic> json) {
    return SlatokiPlaceDto(
      place: PlaceDto.fromJson(json),
      womenVerificationLevel: json["womenVerificationLevel"] as String,
    );
  }

  final PlaceDto place;
  final String womenVerificationLevel;

  SlatokiPlace toEntity() {
    return SlatokiPlace(
      place: place.toEntity(),
      womenVerificationLevel: womenVerificationLevel == "verified_confirmed"
          ? WomenVerificationLevel.verifiedConfirmed
          : WomenVerificationLevel.generic,
    );
  }
}
