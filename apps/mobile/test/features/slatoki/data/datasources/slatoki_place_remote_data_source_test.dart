import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/slatoki/data/datasources/slatoki_place_remote_data_source.dart";
import "package:rahati/features/slatoki/domain/repositories/slatoki_place_repository.dart";

const _center = Coordinates(latitude: 36.75, longitude: 3.06);

Map<String, dynamic> _placeJson() => <String, dynamic>{
  "id": "1",
  "placeKind": "station",
  "name": <String, dynamic>{"fr": "F", "ar": "A", "en": "E"},
  "position": <String, dynamic>{
    "type": "Point",
    "coordinates": <double>[3.06, 36.75],
  },
  "pinColor": "magenta",
  "distanceMeters": 50.0,
  "averageRating": null,
  "reviewCount": 0,
  "isFree": true,
  "tags": <String>["prayer"],
  "womenVerificationLevel": "generic",
};

void main() {
  group("SlatokiPlaceRemoteDataSource", () {
    test("throws SlatokiApiNotConfiguredFailure when baseUrl is null", () {
      final source = SlatokiPlaceRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.fetchSlatokiPlaces(center: _center),
        throwsA(isA<SlatokiApiNotConfiguredFailure>()),
      );
    });

    test("requests GET {baseUrl}/v1/slatoki/places with lat/lng, no filter "
        "param, and parses a 200 JSON response", () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode(<String, dynamic>{
            "data": <Map<String, dynamic>>[_placeJson()],
          }),
          200,
        );
      });
      final source = SlatokiPlaceRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      final dtos = await source.fetchSlatokiPlaces(center: _center);

      expect(capturedUri?.path, "/v1/slatoki/places");
      expect(capturedUri?.queryParameters["lat"], "36.75");
      expect(capturedUri?.queryParameters["lng"], "3.06");
      expect(capturedUri?.queryParameters.containsKey("filter"), isFalse);
      expect(dtos, hasLength(1));
      expect(dtos.single.place.id, "1");
    });

    test("throws SlatokiPlaceFetchFailure on a non-200 response", () {
      final client = MockClient(
        (request) async => http.Response("server error", 500),
      );
      final source = SlatokiPlaceRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.fetchSlatokiPlaces(center: _center),
        throwsA(isA<SlatokiPlaceFetchFailure>()),
      );
    });

    test("tolerates a response with no data key (empty result)", () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode(<String, dynamic>{}), 200),
      );
      final source = SlatokiPlaceRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      final dtos = await source.fetchSlatokiPlaces(center: _center);
      expect(dtos, isEmpty);
    });
  });
}
