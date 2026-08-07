import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/route.dart";
import "package:rahati/features/map_discovery/domain/repositories/route_repository.dart";
import "package:rahati/features/map_discovery/domain/usecases/get_route.dart";

class _FakeRouteRepository implements RouteRepository {
  _FakeRouteRepository({this.result, this.failure});

  final NavigationRoute? result;
  final RouteRepositoryFailure? failure;
  Coordinates? lastOrigin;
  Coordinates? lastDestination;

  @override
  Future<NavigationRoute> getWalkingRoute({
    required Coordinates origin,
    required Coordinates destination,
  }) async {
    lastOrigin = origin;
    lastDestination = destination;
    if (failure != null) throw failure!;
    return result ??
        const NavigationRoute(
          points: <Coordinates>[],
          distanceMeters: 0,
          durationSeconds: 0,
        );
  }
}

void main() {
  group("GetRoute", () {
    const origin = Coordinates(latitude: 36.75, longitude: 3.06);
    const destination = Coordinates(latitude: 36.751, longitude: 3.061);

    test(
      "delegates to the repository with the given origin/destination",
      () async {
        const route = NavigationRoute(
          points: <Coordinates>[origin, destination],
          distanceMeters: 500,
          durationSeconds: 360,
        );
        final repo = _FakeRouteRepository(result: route);
        final usecase = GetRoute(repo);

        final result = await usecase(origin: origin, destination: destination);

        expect(result, same(route));
        expect(repo.lastOrigin, origin);
        expect(repo.lastDestination, destination);
      },
    );

    test("propagates repository failures", () {
      final repo = _FakeRouteRepository(failure: const RouteNotFoundFailure());
      final usecase = GetRoute(repo);

      expect(
        () => usecase(origin: origin, destination: destination),
        throwsA(isA<RouteNotFoundFailure>()),
      );
    });
  });
}
