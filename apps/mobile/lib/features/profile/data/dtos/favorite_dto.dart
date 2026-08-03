import "../../../map_discovery/domain/entities/place.dart" show PlaceKind;
import "../../domain/entities/favorite.dart";

/// JSON mapping for the `Favorite` schema in docs/api/openapi.yaml — a
/// nullable `stationId`/`thirdPartyPlaceId` pair (exactly one non-null),
/// not a `placeType` discriminator string, so [placeKind]/[placeId] are
/// derived rather than parsed directly. [placeName]/[distanceMeters]
/// aren't on the wire schema at all — [toEntity] takes them as resolved
/// inputs (see `RestFavoriteRepository`), matching [Favorite]'s own doc
/// comment on why those fields are denormalized onto the domain entity.
class FavoriteDto {
  const FavoriteDto({
    required this.id,
    required this.stationId,
    required this.thirdPartyPlaceId,
    required this.notifyOnAvailable,
  });

  factory FavoriteDto.fromJson(Map<String, dynamic> json) {
    return FavoriteDto(
      id: json["id"] as String,
      stationId: json["stationId"] as String?,
      thirdPartyPlaceId: json["thirdPartyPlaceId"] as String?,
      notifyOnAvailable: json["notifyOnAvailable"] as bool,
    );
  }

  final String id;
  final String? stationId;
  final String? thirdPartyPlaceId;
  final bool notifyOnAvailable;

  PlaceKind get placeKind =>
      stationId != null ? PlaceKind.station : PlaceKind.thirdPartyPlace;

  String get placeId => stationId ?? thirdPartyPlaceId!;

  Favorite toEntity({required String placeName, double? distanceMeters}) {
    return Favorite(
      id: id,
      placeKind: placeKind,
      placeId: placeId,
      placeName: placeName,
      distanceMeters: distanceMeters,
      notifyOnAvailable: notifyOnAvailable,
    );
  }
}
