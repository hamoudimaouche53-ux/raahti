// Traces to: US-01.1.2 (FR-MAP-02, clustering), docs/adr — see the doc
// comment on clusterPlaces() for why this is hand-rolled rather than a
// pub.dev plugin.
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/presentation/clustering/map_marker_item.dart";
import "package:rahati/features/map_discovery/presentation/clustering/place_clusterer.dart";

const _algiers = 36.75;

Place _placeAt(String id, double lat, double lng) => Place(
  id: id,
  placeKind: PlaceKind.station,
  name: const LocalizedText(fr: "F", ar: "A", en: "E"),
  position: Coordinates(latitude: lat, longitude: lng),
  pinColor: PinColor.blue,
  distanceMeters: 0,
  averageRating: null,
  reviewCount: 0,
  isFree: true,
  tags: const <String>[],
);

void main() {
  group("clusterPlaces", () {
    test("returns an empty list for no places", () {
      final result = clusterPlaces(
        places: const [],
        zoom: 12,
        referenceLatitude: _algiers,
      );
      expect(result, isEmpty);
    });

    test("a single place is never clustered", () {
      final result = clusterPlaces(
        places: [_placeAt("1", _algiers, 3.06)],
        zoom: 12,
        referenceLatitude: _algiers,
      );
      expect(result, hasLength(1));
      expect(result.single, isA<SinglePlaceMarkerItem>());
    });

    test("two places at the same position cluster together", () {
      final result = clusterPlaces(
        places: [_placeAt("1", _algiers, 3.06), _placeAt("2", _algiers, 3.06)],
        zoom: 12,
        referenceLatitude: _algiers,
      );
      expect(result, hasLength(1));
      final item = result.single as PlaceClusterItem;
      expect(item.count, 2);
    });

    test(
      "two places 10km apart do not cluster at zoom 12 (city-level zoom)",
      () {
        final result = clusterPlaces(
          places: [_placeAt("1", _algiers, 3.06), _placeAt("2", 36.84, 3.06)],
          zoom: 12,
          referenceLatitude: _algiers,
        );
        expect(result, hasLength(2));
        expect(result, everyElement(isA<SinglePlaceMarkerItem>()));
      },
    );

    test("the same two places DO cluster at a much lower (more zoomed-out) "
        "zoom level — clustering is zoom-dependent", () {
      final result = clusterPlaces(
        places: [_placeAt("1", _algiers, 3.06), _placeAt("2", 36.84, 3.06)],
        zoom: 4,
        referenceLatitude: _algiers,
      );
      expect(result, hasLength(1));
      expect(result.single, isA<PlaceClusterItem>());
    });

    test("a cluster's position is the centroid of its member places", () {
      final result = clusterPlaces(
        places: [_placeAt("1", 36.7495, 3.06), _placeAt("2", 36.7505, 3.06)],
        zoom: 12,
        referenceLatitude: _algiers,
      );
      final item = result.single as PlaceClusterItem;
      expect(item.position.latitude, closeTo(36.75, 0.0001));
      expect(item.position.longitude, closeTo(3.06, 0.0001));
    });

    test("three places: two close together cluster, one far stays single", () {
      final result = clusterPlaces(
        places: [
          _placeAt("1", _algiers, 3.06),
          _placeAt("2", _algiers, 3.0601), // ~9m away — clusters with #1
          _placeAt("3", 36.84, 3.06), // ~10km away — stays separate
        ],
        zoom: 12,
        referenceLatitude: _algiers,
      );
      expect(result, hasLength(2));
      final clusters = result.whereType<PlaceClusterItem>();
      final singles = result.whereType<SinglePlaceMarkerItem>();
      expect(clusters, hasLength(1));
      expect(clusters.single.count, 2);
      expect(singles, hasLength(1));
    });
  });
}
