// Traces to: US-01.1.4, US-01.1.5 (FR-MAP-04, FR-MAP-05).
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/place_filter.dart";
import "package:rahati/features/map_discovery/domain/usecases/filter_places.dart";

const _position = Coordinates(latitude: 36.75, longitude: 3.06);

Place _place({
  required String id,
  PlaceKind placeKind = PlaceKind.thirdPartyPlace,
  PinColor pinColor = PinColor.green,
  bool isFree = true,
  double distanceMeters = 100,
  LocalizedText? name,
}) => Place(
  id: id,
  placeKind: placeKind,
  name: name ?? const LocalizedText(fr: "F", ar: "A", en: "E"),
  position: _position,
  pinColor: pinColor,
  distanceMeters: distanceMeters,
  averageRating: null,
  reviewCount: 0,
  isFree: isFree,
  tags: const <String>[],
);

void main() {
  group("filterPlaces", () {
    test("returns the same places when the filter is inactive", () {
      final places = [_place(id: "1"), _place(id: "2")];
      final result = filterPlaces(places: places, filter: const PlaceFilter());
      expect(result, places);
    });

    test("full-text search matches the French name (case-insensitive)", () {
      final target = _place(
        id: "1",
        name: const LocalizedText(
          fr: "Station Didouche",
          ar: "أ",
          en: "Didouche",
        ),
      );
      final other = _place(id: "2");
      final result = filterPlaces(
        places: [target, other],
        filter: const PlaceFilter(searchQuery: "didouche"),
      );
      expect(result, [target]);
    });

    test("full-text search also matches the English and Arabic names", () {
      final place = _place(
        id: "1",
        name: const LocalizedText(fr: "F", ar: "محطة", en: "Station"),
      );
      expect(
        filterPlaces(
          places: [place],
          filter: const PlaceFilter(searchQuery: "station"),
        ),
        [place],
      );
      expect(
        filterPlaces(
          places: [place],
          filter: const PlaceFilter(searchQuery: "محطة"),
        ),
        [place],
      );
    });

    test("full-text search excludes non-matching places", () {
      final result = filterPlaces(
        places: [_place(id: "1")],
        filter: const PlaceFilter(searchQuery: "no such place"),
      );
      expect(result, isEmpty);
    });

    test("category filter: free matches only free places", () {
      final free = _place(id: "1", isFree: true);
      final paid = _place(id: "2", isFree: false);
      final result = filterPlaces(
        places: [free, paid],
        filter: const PlaceFilter(categories: {PlaceCategory.free}),
      );
      expect(result, [free]);
    });

    test("category filter: paid matches only non-free places", () {
      final free = _place(id: "1", isFree: true);
      final paid = _place(id: "2", isFree: false);
      final result = filterPlaces(
        places: [free, paid],
        filter: const PlaceFilter(categories: {PlaceCategory.paid}),
      );
      expect(result, [paid]);
    });

    test("category filter: rahatiUnit matches only stations", () {
      final station = _place(id: "1", placeKind: PlaceKind.station);
      final thirdParty = _place(id: "2", placeKind: PlaceKind.thirdPartyPlace);
      final result = filterPlaces(
        places: [station, thirdParty],
        filter: const PlaceFilter(categories: {PlaceCategory.rahatiUnit}),
      );
      expect(result, [station]);
    });

    test("category filter: slatoki matches only magenta-pinned places", () {
      final slatoki = _place(id: "1", pinColor: PinColor.magenta);
      final other = _place(id: "2", pinColor: PinColor.blue);
      final result = filterPlaces(
        places: [slatoki, other],
        filter: const PlaceFilter(categories: {PlaceCategory.slatoki}),
      );
      expect(result, [slatoki]);
    });

    test("multiple selected categories combine with OR", () {
      final free = _place(id: "1", isFree: true, pinColor: PinColor.green);
      final slatoki = _place(
        id: "2",
        isFree: false,
        pinColor: PinColor.magenta,
      );
      final neither = _place(
        id: "3",
        isFree: false,
        pinColor: PinColor.blue,
        placeKind: PlaceKind.thirdPartyPlace,
      );
      final result = filterPlaces(
        places: [free, slatoki, neither],
        filter: const PlaceFilter(
          categories: {PlaceCategory.free, PlaceCategory.slatoki},
        ),
      );
      expect(result, containsAll([free, slatoki]));
      expect(result, isNot(contains(neither)));
    });

    test("distance filter excludes places beyond the cap", () {
      final near = _place(id: "1", distanceMeters: 500);
      final far = _place(id: "2", distanceMeters: 2000);
      final result = filterPlaces(
        places: [near, far],
        filter: const PlaceFilter(distance: DistanceFilter.under1km),
      );
      expect(result, [near]);
    });

    test("a place exactly at the distance cap is included (<=, not <)", () {
      final place = _place(id: "1", distanceMeters: 1000);
      final result = filterPlaces(
        places: [place],
        filter: const PlaceFilter(distance: DistanceFilter.under1km),
      );
      expect(result, [place]);
    });

    test("all dimensions compose with AND", () {
      final match = _place(
        id: "1",
        isFree: true,
        distanceMeters: 400,
        name: const LocalizedText(
          fr: "Toilettes Alger",
          ar: "أ",
          en: "Algiers WC",
        ),
      );
      final wrongCategory = _place(
        id: "2",
        isFree: false,
        distanceMeters: 400,
        name: const LocalizedText(
          fr: "Toilettes Alger",
          ar: "أ",
          en: "Algiers WC",
        ),
      );
      final tooFar = _place(
        id: "3",
        isFree: true,
        distanceMeters: 5000,
        name: const LocalizedText(
          fr: "Toilettes Alger",
          ar: "أ",
          en: "Algiers WC",
        ),
      );
      final noSearchMatch = _place(id: "4", isFree: true, distanceMeters: 400);

      final result = filterPlaces(
        places: [match, wrongCategory, tooFar, noSearchMatch],
        filter: const PlaceFilter(
          searchQuery: "alger",
          categories: {PlaceCategory.free},
          distance: DistanceFilter.under1km,
        ),
      );
      expect(result, [match]);
    });

    test("an active filter matching nothing returns an empty list", () {
      final result = filterPlaces(
        places: [_place(id: "1")],
        filter: const PlaceFilter(searchQuery: "unmatched-query"),
      );
      expect(result, isEmpty);
    });
  });
}
