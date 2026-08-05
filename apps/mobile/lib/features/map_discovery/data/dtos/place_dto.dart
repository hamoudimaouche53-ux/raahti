import "../../domain/entities/coordinates.dart";
import "../../domain/entities/place.dart";

/// JSON mapping for the `PlaceSummary` schema in docs/api/openapi.yaml
/// (`GET /places/nearby`). The only layer allowed to know this wire format
/// — the Domain layer sees only [Place].
class PlaceDto {
  const PlaceDto({
    required this.id,
    required this.placeKind,
    required this.name,
    required this.position,
    required this.pinColor,
    required this.distanceMeters,
    required this.averageRating,
    required this.reviewCount,
    required this.isFree,
    required this.tags,
  });

  factory PlaceDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> name = json["name"] as Map<String, dynamic>;
    final Map<String, dynamic> position =
        json["position"] as Map<String, dynamic>;
    final List<dynamic> coordinates = position["coordinates"] as List<dynamic>;

    return PlaceDto(
      id: json["id"] as String,
      placeKind: json["placeKind"] as String,
      name: LocalizedText(
        fr: name["fr"] as String,
        ar: name["ar"] as String,
        // `en` is a Phase 3 API-contract extension over the Phase 1 draft
        // (ADR-0017) — tolerate its absence from an older payload rather
        // than throwing, falling back to French.
        en: (name["en"] as String?) ?? name["fr"] as String,
      ),
      // GeoJSON order is [lng, lat] (docs/api/api-architecture.md §4).
      position: Coordinates(
        longitude: (coordinates[0] as num).toDouble(),
        latitude: (coordinates[1] as num).toDouble(),
      ),
      pinColor: json["pinColor"] as String,
      // Absent on `StationDetail`/`ThirdPartyPlaceDetail` responses (`GET
      // /stations/{id}`, `GET /third-party-places/{id}`) — there is no
      // search origin for a by-id detail lookup, unlike `GET /places/nearby`
      // and `GET /slatoki/places`, which always compute a real one. Found on
      // a real device against the real backend (Release Validation,
      // docs/phase-5-release-validation-report.md): the detail sheet's
      // lazy detail fetch threw here and surfaced as a generic "Impossible
      // de charger les détails de ce lieu." error. The distance shown in
      // the sheet's header always comes from the already-known search-result
      // `Place` passed into `PlaceDetailSheet`, never from this embedded
      // summary (see `PlaceDetailSheet`'s own `place.distanceMeters` usage),
      // so defaulting to 0 here is inert, not a displayed value.
      distanceMeters: (json["distanceMeters"] as num?)?.toDouble() ?? 0,
      averageRating: (json["averageRating"] as num?)?.toDouble(),
      reviewCount: json["reviewCount"] as int,
      isFree: json["isFree"] as bool,
      tags:
          (json["tags"] as List<dynamic>?)?.cast<String>() ?? const <String>[],
    );
  }

  final String id;
  final String placeKind;
  final LocalizedText name;
  final Coordinates position;
  final String pinColor;
  final double distanceMeters;
  final double? averageRating;
  final int reviewCount;
  final bool isFree;
  final List<String> tags;

  Place toEntity() {
    return Place(
      id: id,
      placeKind: placeKind == "station"
          ? PlaceKind.station
          : PlaceKind.thirdPartyPlace,
      name: name,
      position: position,
      pinColor: PinColor.values.firstWhere(
        (v) => v.name == pinColor,
        orElse: () => PinColor.blue,
      ),
      distanceMeters: distanceMeters,
      averageRating: averageRating,
      reviewCount: reviewCount,
      isFree: isFree,
      tags: tags,
    );
  }
}
