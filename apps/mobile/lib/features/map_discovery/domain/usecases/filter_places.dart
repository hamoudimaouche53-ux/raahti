import "../entities/place.dart";
import "../entities/place_filter.dart";

/// Applies a [PlaceFilter] to an already-fetched list of nearby places.
///
/// Pure and framework-free (same discipline as `clusterPlaces()`,
/// ADR-0020) so it is unit-testable without Flutter/Riverpod, and so a
/// future server-side filter (sending `q`/`type[]` to `GET
/// /places/nearby`, both already defined in docs/api/openapi.yaml) can
/// replace or complement this client-side pass without touching call sites
/// beyond the data layer — the [PlaceFilter] contract stays the same either
/// way.
///
/// Dimensions combine with AND; multiple selected [PlaceFilter.categories]
/// combine with OR (matches the FR-MAP-05 multi-select chip semantics: "show
/// me Free OR RAHETI", not "show me places that are both").
List<Place> filterPlaces({
  required List<Place> places,
  required PlaceFilter filter,
}) {
  if (!filter.isActive) return places;

  final String query = filter.searchQuery.trim().toLowerCase();
  final double? maxDistanceMeters = filter.distance.maxMeters;

  return places
      .where((place) {
        if (query.isNotEmpty && !_matchesSearch(place, query)) return false;
        if (filter.categories.isNotEmpty &&
            !_matchesAnyCategory(place, filter.categories)) {
          return false;
        }
        if (maxDistanceMeters != null &&
            place.distanceMeters > maxDistanceMeters) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
}

/// Matches against all three [Place.name] languages regardless of the
/// active UI locale — a more forgiving "full-text search" than restricting
/// to whatever language is currently displayed.
bool _matchesSearch(Place place, String lowercaseQuery) {
  return place.name.fr.toLowerCase().contains(lowercaseQuery) ||
      place.name.en.toLowerCase().contains(lowercaseQuery) ||
      place.name.ar.contains(lowercaseQuery);
}

bool _matchesAnyCategory(Place place, Set<PlaceCategory> categories) {
  for (final PlaceCategory category in categories) {
    final bool matches = switch (category) {
      PlaceCategory.free => place.isFree,
      PlaceCategory.paid => !place.isFree,
      PlaceCategory.rahatiUnit => place.placeKind == PlaceKind.station,
      PlaceCategory.slatoki => place.pinColor == PinColor.magenta,
    };
    if (matches) return true;
  }
  return false;
}
