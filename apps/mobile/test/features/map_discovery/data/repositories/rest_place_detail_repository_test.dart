import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/data/datasources/place_detail_remote_data_source.dart";
import "package:rahati/features/map_discovery/data/repositories/rest_place_detail_repository.dart";
import "package:rahati/features/map_discovery/domain/repositories/place_repository.dart";

Map<String, dynamic> _stationJson() => <String, dynamic>{
  "id": "s1",
  "placeKind": "station",
  "name": <String, dynamic>{"fr": "F", "ar": "A", "en": "E"},
  "position": <String, dynamic>{
    "type": "Point",
    "coordinates": <double>[3.06, 36.75],
  },
  "pinColor": "amber",
  "distanceMeters": 50.0,
  "averageRating": null,
  "reviewCount": 0,
  "isFree": false,
  "tags": <String>[],
  "configuration": "fixe",
  "status": "active",
  "cabins": <dynamic>[],
};

void main() {
  group("RestPlaceDetailRepository", () {
    test("getStationDetail returns the parsed entity on success", () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode(_stationJson()), 200),
      );
      final repo = RestPlaceDetailRepository(
        PlaceDetailRemoteDataSource(client, baseUrl: "http://test.local"),
      );

      final detail = await repo.getStationDetail("s1");

      expect(detail.summary.id, "s1");
    });

    test("propagates a PlaceFetchFailure on a non-200 response — no offline "
        "fallback for detail data (unlike RestPlaceRepository's cache)", () {
      final client = MockClient(
        (request) async => http.Response("server error", 500),
      );
      final repo = RestPlaceDetailRepository(
        PlaceDetailRemoteDataSource(client, baseUrl: "http://test.local"),
      );

      expect(
        () => repo.getStationDetail("s1"),
        throwsA(isA<PlaceFetchFailure>()),
      );
    });
  });
}
