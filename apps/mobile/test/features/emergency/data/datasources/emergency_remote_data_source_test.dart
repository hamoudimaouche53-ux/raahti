import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/emergency/data/datasources/emergency_remote_data_source.dart";
import "package:rahati/features/emergency/domain/repositories/emergency_repository.dart";

Map<String, dynamic> _resultJson() => <String, dynamic>{
  "place": <String, dynamic>{
    "id": "place-1",
    "placeKind": "station",
    "name": <String, dynamic>{
      "fr": "Station Didouche",
      "ar": "محطة ديدوش",
      "en": "Didouche Station",
    },
    "position": <String, dynamic>{
      "coordinates": <double>[3.06, 36.75],
    },
    "pinColor": "green",
    "distanceMeters": 180.0,
    "averageRating": null,
    "reviewCount": 0,
    "isFree": true,
    "tags": <String>[],
  },
  "nearestCabinId": "cabin-1",
  "discountEligible": true,
};

void main() {
  group("EmergencyRemoteDataSource.fetchNearestFacility", () {
    test("throws EmergencyApiNotConfiguredFailure when baseUrl is null", () {
      final source = EmergencyRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.fetchNearestFacility(lat: 36.75, lng: 3.06),
        throwsA(isA<EmergencyApiNotConfiguredFailure>()),
      );
    });

    test("GETs {baseUrl}/v1/emergency/nearest-facility with lat/lng query "
        "parameters and parses a 200 response", () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        // Explicit UTF-8 content-type — without it, `http.Response`'s
        // default (`latin1`, per its own doc comment) can't encode the
        // fixture's Arabic place name and throws at construction time.
        return http.Response(
          jsonEncode(_resultJson()),
          200,
          headers: <String, String>{
            "content-type": "application/json; charset=utf-8",
          },
        );
      });
      final source = EmergencyRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      final dto = await source.fetchNearestFacility(lat: 36.75, lng: 3.06);

      expect(capturedUri?.path, "/v1/emergency/nearest-facility");
      expect(capturedUri?.queryParameters["lat"], "36.75");
      expect(capturedUri?.queryParameters["lng"], "3.06");
      expect(dto?.place.id, "place-1");
      expect(dto?.discountEligible, isTrue);
    });

    test("returns null on a 404 response (no facility found)", () async {
      final client = MockClient(
        (request) async => http.Response("not found", 404),
      );
      final source = EmergencyRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      final dto = await source.fetchNearestFacility(lat: 0, lng: 0);

      expect(dto, isNull);
    });

    test(
      "throws EmergencyRequestFailure on any other non-200/404 response",
      () {
        final client = MockClient(
          (request) async => http.Response("server error", 500),
        );
        final source = EmergencyRemoteDataSource(
          client,
          baseUrl: "http://test.local",
        );

        expect(
          () => source.fetchNearestFacility(lat: 0, lng: 0),
          throwsA(isA<EmergencyRequestFailure>()),
        );
      },
    );

    test("throws EmergencyRequestFailure when the network call throws", () {
      final client = MockClient((request) async => throw Exception("boom"));
      final source = EmergencyRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.fetchNearestFacility(lat: 0, lng: 0),
        throwsA(isA<EmergencyRequestFailure>()),
      );
    });
  });
}
