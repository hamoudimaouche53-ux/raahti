import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/data/datasources/place_detail_remote_data_source.dart";
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

Map<String, dynamic> _thirdPartyJson() => <String, dynamic>{
  "id": "p1",
  "placeKind": "third_party_place",
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
  "placeType": "mosque",
  "declaredStatus": "open",
  "statusSource": "community",
};

void main() {
  group("PlaceDetailRemoteDataSource", () {
    test("throws ApiNotConfiguredFailure when baseUrl is null", () {
      final source = PlaceDetailRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.fetchStationDetail("s1"),
        throwsA(isA<ApiNotConfiguredFailure>()),
      );
    });

    test(
      "requests GET {baseUrl}/v1/stations/{id} and parses a StationDetailDto",
      () async {
        Uri? capturedUri;
        final client = MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode(_stationJson()), 200);
        });
        final source = PlaceDetailRemoteDataSource(
          client,
          baseUrl: "http://test.local",
        );

        final dto = await source.fetchStationDetail("s1");

        expect(capturedUri?.path, "/v1/stations/s1");
        expect(dto.summary.id, "s1");
        expect(dto.configuration, "fixe");
      },
    );

    test("requests GET {baseUrl}/v1/third-party-places/{id} and parses a "
        "ThirdPartyPlaceDetailDto", () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode(_thirdPartyJson()), 200);
      });
      final source = PlaceDetailRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      final dto = await source.fetchThirdPartyPlaceDetail("p1");

      expect(capturedUri?.path, "/v1/third-party-places/p1");
      expect(dto.summary.id, "p1");
      expect(dto.declaredStatus, "open");
    });

    test("throws PlaceFetchFailure on a non-200 response", () {
      final client = MockClient(
        (request) async => http.Response("server error", 500),
      );
      final source = PlaceDetailRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.fetchStationDetail("s1"),
        throwsA(isA<PlaceFetchFailure>()),
      );
    });

    test("throws PlaceFetchFailure when the client throws (unreachable)", () {
      final client = MockClient((request) async {
        throw Exception("unreachable");
      });
      final source = PlaceDetailRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.fetchThirdPartyPlaceDetail("p1"),
        throwsA(isA<PlaceFetchFailure>()),
      );
    });
  });
}
