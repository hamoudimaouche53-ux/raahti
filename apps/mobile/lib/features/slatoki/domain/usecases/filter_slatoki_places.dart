import "../../../map_discovery/domain/entities/place.dart" show PlaceKind;
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
///
/// [PlaceKind.station] entries always match every filter, mirroring the
/// backend's own documented rule (`SlatokiQueryService.matchesFilter`,
/// apps/backend/.../slatoki-query.service.ts: "A RAHETI Slatoki tent
/// always offers both prayer and wudu... so it matches every filter value
/// unconditionally") — Stations carry no `tags` at all (ERD §3.5/§3.6:
/// tags are Third-Party-Place-only), so checking `tags.contains(...)`
/// for a Station always evaluated false, silently hiding every RAHETI
/// Slatoki tent under every filter tab. Found on a real device against
/// the real backend (Release Validation,
/// docs/phase-5-release-validation-report.md) — the backend correctly
/// returned a seeded qualifying Station, but it never appeared in the
/// list under any tab.
List<SlatokiPlace> filterSlatokiPlaces(
  List<SlatokiPlace> places,
  PrayerFacilityFilter filter,
) {
  return places
      .where((slatokiPlace) {
        if (slatokiPlace.place.placeKind == PlaceKind.station) {
          return true;
        }
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
