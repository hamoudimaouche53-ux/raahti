import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/data/datasources/route_remote_data_source.dart";
import "package:rahati/features/map_discovery/data/repositories/rest_route_repository.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/repositories/route_repository.dart";

const _origin = Coordinates(latitude: 36.75, longitude: 3.06);
const _destination = Coordinates(latitude: 36.751, longitude: 3.061);

RestRouteRepository _repository(http.Client client) {
  return RestRouteRepository(
    RouteRemoteDataSource(client, baseUrl: "https://api.test"),
  );
}

void main() {
  group("RestRouteRepository", () {
    test("returns a NavigationRoute with the polyline decoded", () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode(<String, dynamic>{
            "polyline": r"_p~iF~ps|U_ulLnnqC",
            "distanceMeters": 500.0,
            "durationSeconds": 360.0,
          }),
          200,
        ),
      );

      final route = await _repository(
        client,
      ).getWalkingRoute(origin: _origin, destination: _destination);

      expect(route.points, hasLength(2));
      expect(route.distanceMeters, 500.0);
      expect(route.durationSeconds, 360.0);
    });

    test("propagates RouteNotFoundFailure from the remote data source", () {
      final client = MockClient(
        (request) async => http.Response("not found", 404),
      );

      expect(
        () => _repository(
          client,
        ).getWalkingRoute(origin: _origin, destination: _destination),
        throwsA(isA<RouteNotFoundFailure>()),
      );
    });
  });
}
