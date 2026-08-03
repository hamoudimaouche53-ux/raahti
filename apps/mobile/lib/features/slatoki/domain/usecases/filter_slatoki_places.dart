import "../entities/prayer_facility_filter.dart";
import "../entities/slatoki_place.dart";

/// Pure filtering function (FR-SLK-03) — same discipline as
/// `map_discovery`'s `clusterPlaces()`/`filterPlaces()` (ADR-0020/ADR-0021):
/// no Flutter/Riverpod dependency, unit-testable in isolation. Reads
/// [Place.tags]' `"prayer"`/`"wudu"` values (the same tag vocabulary
/// EPIC-01's place-detail sheet already renders — ERD §3.5's tag lookup
/// table), applied client-side to whatever `getSlatokiPlaces()` already
/// fetched rather than re-querying the server's `filter` parameter per tab
/// switch — the same client-side-filtering call ADR-0021 made for the Map.
List<SlatokiPlace> filterSlatokiPlaces(
  List<SlatokiPlace> places,
  PrayerFacilityFilter filter,
) {
  return places
      .where((slatokiPlace) {
        final List<String> tags = slatokiPlace.place.tags;
        final bool hasPrayer = tags.contains("prayer");
        final bool hasWudu = tags.contains("wudu");
        return switch (filter) {
          PrayerFacilityFilter.prayerOnly => hasPrayer,
          PrayerFacilityFilter.wuduOnly => hasWudu,
          PrayerFacilityFilter.prayerAndWudu => hasPrayer && hasWudu,
        };
      })
      .toList(growable: false);
}
