import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/slatoki/domain/entities/prayer_facility_filter.dart";
import "package:rahati/features/slatoki/domain/entities/slatoki_place.dart";
import "package:rahati/features/slatoki/domain/entities/women_verification_level.dart";
import "package:rahati/features/slatoki/domain/usecases/filter_slatoki_places.dart";

const _center = Coordinates(latitude: 36.7538, longitude: 3.0588);

SlatokiPlace _place(
  String id,
  List<String> tags, {
  PlaceKind placeKind = PlaceKind.thirdPartyPlace,
}) => SlatokiPlace(
  place: Place(
    id: id,
    placeKind: placeKind,
    name: LocalizedText(fr: "Lieu $id", ar: "مكان $id", en: "Place $id"),
    position: _center,
    pinColor: PinColor.magenta,
    distanceMeters: 100,
    averageRating: null,
    reviewCount: 0,
    isFree: true,
    tags: tags,
  ),
  womenVerificationLevel: WomenVerificationLevel.generic,
);

void main() {
  final SlatokiPlace prayerOnlyPlace = _place("1", ["prayer"]);
  final SlatokiPlace wuduOnlyPlace = _place("2", ["wudu"]);
  final SlatokiPlace bothPlace = _place("3", ["prayer", "wudu"]);
  final SlatokiPlace neitherPlace = _place("4", ["women_confirmed"]);
  final List<SlatokiPlace> all = [
    prayerOnlyPlace,
    wuduOnlyPlace,
    bothPlace,
    neitherPlace,
  ];

  test("prayerOnly matches every place with a 'prayer' tag", () {
    final result = filterSlatokiPlaces(all, PrayerFacilityFilter.prayerOnly);
    expect(result, containsAll([prayerOnlyPlace, bothPlace]));
    expect(result, isNot(contains(wuduOnlyPlace)));
    expect(result, isNot(contains(neitherPlace)));
  });

  test("wuduOnly matches every place with a 'wudu' tag", () {
    final result = filterSlatokiPlaces(all, PrayerFacilityFilter.wuduOnly);
    expect(result, containsAll([wuduOnlyPlace, bothPlace]));
    expect(result, isNot(contains(prayerOnlyPlace)));
  });

  test("prayerAndWudu matches only places with both tags", () {
    final result = filterSlatokiPlaces(all, PrayerFacilityFilter.prayerAndWudu);
    expect(result, [bothPlace]);
  });

  test("empty input returns empty output for every filter", () {
    for (final filter in PrayerFacilityFilter.values) {
      expect(filterSlatokiPlaces(const [], filter), isEmpty);
    }
  });

  test("a place with neither tag never matches any filter", () {
    for (final filter in PrayerFacilityFilter.values) {
      expect(filterSlatokiPlaces([neitherPlace], filter), isEmpty);
    }
  });

  test(
    "a station always matches every filter, regardless of (always-empty) "
    "tags — mirrors the backend's own rule (SlatokiQueryService.matchesFilter: "
    "'A RAHETI Slatoki tent always offers both prayer and wudu'). Regression: "
    "found on a real device against the real backend — a qualifying Station "
    "the backend correctly returned never appeared under any filter tab, "
    "because Stations carry no tags at all (ERD §3.5/§3.6) and the old "
    "implementation didn't special-case placeKind.",
    () {
      final SlatokiPlace station = _place(
        "5",
        const [],
        placeKind: PlaceKind.station,
      );
      for (final filter in PrayerFacilityFilter.values) {
        expect(filterSlatokiPlaces([station], filter), [station]);
      }
    },
  );
}
