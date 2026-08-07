import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/data/datasources/route_remote_data_source.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/repositories/route_repository.dart";

const _origin = Coordinates(latitude: 36.75, longitude: 3.06);
const _destination = Coordinates(latitude: 36.751, longitude: 3.061);

Map<String, dynamic> _routeJson() => <String, dynamic>{
  "polyline": r"_p~iF~ps|U_ulLnnqC",
  "distanceMeters": 500.0,
  "durationSeconds": 360.0,
};

void main() {
  group("RouteRemoteDataSource", () {
    test("throws RouteApiNotConfiguredFailure when baseUrl is null", () {
      final source = RouteRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.fetchWalkingRoute(
          origin: _origin,
          destination: _destination,
        ),
        throwsA(isA<RouteApiNotConfiguredFailure>()),
      );
    });

    test("throws RouteApiNotConfiguredFailure when baseUrl is empty", () {
      final source = RouteRemoteDataSource(http.Client(), baseUrl: "");
      expect(
        () => source.fetchWalkingRoute(
          origin: _origin,
          destination: _destination,
        ),
        throwsA(isA<RouteApiNotConfiguredFailure>()),
      );
    });

    test("requests GET {baseUrl}/v1/routes/walking with origin/dest "
        "lat/lng and parses a 200 JSON response into a RouteDto", () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(jsonEncode(_routeJson()), 200);
      });
      final source = RouteRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      final dto = await source.fetchWalkingRoute(
        origin: _origin,
        destination: _destination,
      );

      expect(capturedUri?.path, "/v1/routes/walking");
      expect(capturedUri?.queryParameters["originLat"], "36.75");
      expect(capturedUri?.queryParameters["originLng"], "3.06");
      expect(capturedUri?.queryParameters["destLat"], "36.751");
      expect(capturedUri?.queryParameters["destLng"], "3.061");
      expect(dto.polyline, r"_p~iF~ps|U_ulLnnqC");
      expect(dto.distanceMeters, 500.0);
      expect(dto.durationSeconds, 360.0);
    });

    test("throws RouteNotFoundFailure on a 404 response", () {
      final client = MockClient(
        (request) async => http.Response("not found", 404),
      );
      final source = RouteRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.fetchWalkingRoute(
          origin: _origin,
          destination: _destination,
        ),
        throwsA(isA<RouteNotFoundFailure>()),
      );
    });

    test("throws RouteFetchFailure on a non-200/404 response (e.g. the "
        "backend's upstream routing provider being unavailable, 502)", () {
      final client = MockClient(
        (request) async => http.Response("bad gateway", 502),
      );
      final source = RouteRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.fetchWalkingRoute(
          origin: _origin,
          destination: _destination,
        ),
        throwsA(isA<RouteFetchFailure>()),
      );
    });

    test("throws RouteFetchFailure when the client throws (unreachable)", () {
      final client = MockClient((request) async {
        throw const SocketExceptionStub();
      });
      final source = RouteRemoteDataSource(
        client,
        baseUrl: "http://test.local",
      );

      expect(
        () => source.fetchWalkingRoute(
          origin: _origin,
          destination: _destination,
        ),
        throwsA(isA<RouteFetchFailure>()),
      );
    });
  });
}

/// Stand-in for a real `SocketException` — same rationale as
/// `place_remote_data_source_test.dart`'s identical stub: avoids depending
/// on `dart:io` purely to construct a throwable for this one test.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
