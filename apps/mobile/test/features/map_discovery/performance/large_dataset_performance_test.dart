// Traces to: EPIC-01 close-out "Performance Verification" — validates
// rendering-adjacent pure-function performance (clustering, filtering)
// against a dataset far larger than any realistic "nearby places" query
// (docs/api/openapi.yaml's `GET /places/nearby` is radius-bounded, so a
// production response is expected to be in the tens-to-low-hundreds, not
// thousands — this test deliberately goes past that to establish margin).
//
// These are wall-clock budgets, not micro-benchmarks — generous on purpose
// so they stay robust on a loaded CI machine while still catching an
// accidental O(n^2)-on-every-keystroke regression (a real risk here, since
// both functions re-run on every `MapScreen` rebuild).
import "dart:math";

import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/place_filter.dart";
import "package:rahati/features/map_discovery/domain/usecases/filter_places.dart";
import "package:rahati/features/map_discovery/presentation/clustering/place_clusterer.dart";

const _algiers = 36.75;

List<Place> _syntheticPlaces(int count) {
  final random = Random(
    42,
  ); // deterministic — a flaky perf test is worse than none
  return List<Place>.generate(count, (i) {
    // Spread over roughly a 20km x 20km box around Algiers so clustering
    // has genuine varied density to chew through, not one giant cluster.
    final double lat = _algiers + (random.nextDouble() - 0.5) * 0.18;
    final double lng = 3.06 + (random.nextDouble() - 0.5) * 0.18;
    return Place(
      id: "place-$i",
      placeKind: i.isEven ? PlaceKind.station : PlaceKind.thirdPartyPlace,
      name: LocalizedText(fr: "Lieu $i", ar: "مكان $i", en: "Place $i"),
      position: Coordinates(latitude: lat, longitude: lng),
      pinColor: PinColor.values[i % PinColor.values.length],
      distanceMeters: random.nextDouble() * 5000,
      averageRating: i % 3 == 0 ? null : random.nextDouble() * 5,
      reviewCount: i % 7,
      isFree: i.isEven,
      tags: i % 5 == 0 ? const ["women_confirmed"] : const <String>[],
    );
  });
}

void main() {
  group("clusterPlaces performance", () {
    test("clusters 1000 places at a city-wide zoom in under 500ms", () {
      final places = _syntheticPlaces(1000);
      final stopwatch = Stopwatch()..start();

      final result = clusterPlaces(
        places: places,
        zoom: 12,
        referenceLatitude: _algiers,
      );

      stopwatch.stop();
      expect(result, isNotEmpty);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason:
            "clusterPlaces took ${stopwatch.elapsedMilliseconds}ms for "
            "1000 places — this runs on every MapScreen rebuild, so a "
            "regression here directly costs frame time.",
      );
    });

    test("clusters 500 places at a close-in zoom (mostly single markers) "
        "in under 300ms", () {
      final places = _syntheticPlaces(500);
      final stopwatch = Stopwatch()..start();

      clusterPlaces(places: places, zoom: 18, referenceLatitude: _algiers);

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });
  });

  group("filterPlaces performance", () {
    test("filters 1000 places with an active search+category+distance "
        "filter in under 50ms", () {
      final places = _syntheticPlaces(1000);
      final stopwatch = Stopwatch()..start();

      final result = filterPlaces(
        places: places,
        filter: const PlaceFilter(
          searchQuery: "lieu",
          categories: {PlaceCategory.free, PlaceCategory.rahatiUnit},
          distance: DistanceFilter.under5km,
        ),
      );

      stopwatch.stop();
      expect(result, isNotEmpty);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason:
            "filterPlaces took ${stopwatch.elapsedMilliseconds}ms for "
            "1000 places — this runs on every debounced keystroke/chip tap.",
      );
    });

    test("the filter-then-cluster pipeline (MapScreen's actual per-rebuild "
        "cost) handles 1000 places in under 500ms combined", () {
      final places = _syntheticPlaces(1000);
      final stopwatch = Stopwatch()..start();

      final filtered = filterPlaces(
        places: places,
        filter: const PlaceFilter(categories: {PlaceCategory.free}),
      );
      clusterPlaces(places: filtered, zoom: 13, referenceLatitude: _algiers);

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500),
        reason: "combined pipeline took ${stopwatch.elapsedMilliseconds}ms",
      );
    });
  });
}
