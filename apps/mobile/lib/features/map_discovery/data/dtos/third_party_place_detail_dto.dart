import "../../domain/entities/third_party_place_detail.dart";
import "place_dto.dart";

/// JSON mapping for the `ThirdPartyPlaceDetail` schema in
/// docs/api/openapi.yaml — `allOf: [PlaceSummary, {placeType,
/// declaredStatus, statusSource}]` (`GET /third-party-places/{id}`).
class ThirdPartyPlaceDetailDto {
  const ThirdPartyPlaceDetailDto({
    required this.summary,
    required this.placeType,
    required this.declaredStatus,
    required this.statusSource,
  });

  factory ThirdPartyPlaceDetailDto.fromJson(Map<String, dynamic> json) {
    return ThirdPartyPlaceDetailDto(
      summary: PlaceDto.fromJson(json),
      placeType: json["placeType"] as String,
      declaredStatus: json["declaredStatus"] as String,
      statusSource: json["statusSource"] as String,
    );
  }

  final PlaceDto summary;
  final String placeType;
  final String declaredStatus;
  final String statusSource;

  ThirdPartyPlaceDetail toEntity() {
    return ThirdPartyPlaceDetail(
      summary: summary.toEntity(),
      placeType: switch (placeType) {
        "mosque" => ThirdPartyPlaceType.mosque,
        "business" => ThirdPartyPlaceType.business,
        "gas_station" => ThirdPartyPlaceType.gasStation,
        _ => ThirdPartyPlaceType.other,
      },
      declaredStatus: DeclaredStatus.values.firstWhere(
        (v) => v.name == declaredStatus,
        orElse: () => DeclaredStatus.unknown,
      ),
      statusSource: switch (statusSource) {
        "community" => StatusSource.community,
        "owner_declared" => StatusSource.ownerDeclared,
        _ => StatusSource.community,
      },
    );
  }
}
