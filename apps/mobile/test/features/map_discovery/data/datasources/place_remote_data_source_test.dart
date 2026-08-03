import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/data/datasources/place_remote_data_source.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/repositories/place_repository.dart";

const _center = Coordinates(latitude: 36.75, longitude: 3.06);

Map<String, dynamic> _placeJson() => <String, dynamic>{
  "id": "1",
  "placeKind": "station",
  "name": <String, dynamic>{"fr": "F", "ar": "A", "en": "E"},
  "position": <String, dynamic>{
    "type": "Point",
    "coordinates": <double>[3.06, 36.75],
  },
  "pinColor": "green",
  "distanceMeters": 50.0,
  "averageRating": null,
  "reviewCount": 0,
  "isFree": true,
  "tags": <String>[],
};

void main() {
  group("PlaceRemoteDataSource", () {
    test("throws ApiNotConfiguredFailure when baseUrl is null", () {
      final source = PlaceRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.fetchNearbyPlaces(center: _center, radiusMeters: 2000),
        throwsA(isA<ApiNotConfiguredFailure>()),
      );
    });

    test("throws ApiNotConfiguredFailure when baseUrl is empty", () {
      final source = PlaceRemoteDataSource(http.Client(), baseUrl: "");
      expect(
        () => source.fetchNearbyPlaces(center: _center, radiusMeters: 2000),
        throwsA(isA<ApiNotConfiguredFailure>()),
      );
    });

    test("requests GET {baseUrl}/v1/places/nearby with lat/lng/radiusMeters "
        "and parses a 200 JSON response into PlaceDtos", () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode(<String, dynamic>{
            "data": <Map<String, dynamic>>[_placeJson()],
            "nextCursor": null,
          }),
          200,
        );
      });
      final source = PlaceRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      final dtos = await source.fetchNearbyPlaces(
        center: _center,
        radiusMeters: 1500,
      );

      expect(capturedUri?.path, "/v1/places/nearby");
      expect(capturedUri?.queryParameters["lat"], "36.75");
      expect(capturedUri?.queryParameters["lng"], "3.06");
      expect(capturedUri?.queryParameters["radiusMeters"], "1500");
      expect(dtos, hasLength(1));
      expect(dtos.single.id, "1");
      expect(dtos.single.name.en, "E");
    });

    test("throws PlaceFetchFailure on a non-200 response", () {
      final client = MockClient(
        (request) async => http.Response("server error", 500),
      );
      final source = PlaceRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.fetchNearbyPlaces(center: _center, radiusMeters: 2000),
        throwsA(isA<PlaceFetchFailure>()),
      );
    });

    test("throws PlaceFetchFailure when the client throws (unreachable)", () {
      final client = MockClient((request) async {
        throw const SocketExceptionStub();
      });
      final source = PlaceRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.fetchNearbyPlaces(center: _center, radiusMeters: 2000),
        throwsA(isA<PlaceFetchFailure>()),
      );
    });

    test("tolerates a response with no data key (empty result)", () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode(<String, dynamic>{}), 200),
      );
      final source = PlaceRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      final dtos = await source.fetchNearbyPlaces(
        center: _center,
        radiusMeters: 2000,
      );
      expect(dtos, isEmpty);
    });
  });
}

/// Stand-in for a real `SocketException` — avoids depending on `dart:io`
/// (unavailable/inconsistent across the web target) purely to construct a
/// throwable for this one test.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
