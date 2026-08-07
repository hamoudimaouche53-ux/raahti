import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/route.dart";
import "package:rahati/features/map_discovery/domain/repositories/route_repository.dart";
import "package:rahati/features/map_discovery/presentation/providers/route_providers.dart";

const _destination = Coordinates(latitude: 36.75, longitude: 3.06);
const _otherDestination = Coordinates(latitude: 40, longitude: 5);
// ~22m north of _origin (0.0002° latitude ≈ 22m) — exceeds the 20m
// recalculation threshold.
const _origin = Coordinates(latitude: 36.751, longitude: 3.05);
const _originMovedFar = Coordinates(latitude: 36.7512, longitude: 3.05);
// ~5.5m from _origin — under the threshold.
const _originMovedLittle = Coordinates(latitude: 36.75105, longitude: 3.05);

NavigationRoute _route(double distanceMeters) => NavigationRoute(
  points: const <Coordinates>[],
  distanceMeters: distanceMeters,
  durationSeconds: 1,
);

/// A [RouteRepository] whose responses are controlled one call at a time —
/// lets a test resolve/fail/leave-pending each fetch independently, which
/// is what proving "cancel obsolete requests" and "cache the latest
/// successful route" requires.
class _ScriptedRouteRepository implements RouteRepository {
  final List<Completer<NavigationRoute>> pending =
      <Completer<NavigationRoute>>[];
  int callCount = 0;

  @override
  Future<NavigationRoute> getWalkingRoute({
    required Coordinates origin,
    required Coordinates destination,
  }) {
    callCount++;
    final completer = Completer<NavigationRoute>();
    pending.add(completer);
    return completer.future;
  }
}

void main() {
  late _ScriptedRouteRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _ScriptedRouteRepository();
    container = ProviderContainer(
      overrides: [routeRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  test("fetches once on the first onPositionUpdate call", () async {
    final controller = container.read(
      navigationControllerProvider(_destination).notifier,
    );
    controller.onPositionUpdate(_origin);

    expect(repo.callCount, 1);
    expect(
      container.read(navigationControllerProvider(_destination)).isLoading,
      isTrue,
    );

    repo.pending.single.complete(_route(500));
    await Future<void>.value();

    final state = container.read(navigationControllerProvider(_destination));
    expect(state.route?.distanceMeters, 500);
    expect(state.isLoading, isFalse);
  });

  test(
    "ignores a position update under the 20m recalculation threshold",
    () async {
      final controller = container.read(
        navigationControllerProvider(_destination).notifier,
      );
      controller.onPositionUpdate(_origin);
      repo.pending.single.complete(_route(500));
      await Future<void>.value();

      controller.onPositionUpdate(_originMovedLittle);

      expect(repo.callCount, 1);
    },
  );

  test("recalculates once movement exceeds the 20m threshold, refreshing "
      "the route", () async {
    final controller = container.read(
      navigationControllerProvider(_destination).notifier,
    );
    controller.onPositionUpdate(_origin);
    repo.pending[0].complete(_route(500));
    await Future<void>.value();

    controller.onPositionUpdate(_originMovedFar);
    expect(repo.callCount, 2);
    repo.pending[1].complete(_route(300));
    await Future<void>.value();

    final state = container.read(navigationControllerProvider(_destination));
    expect(state.route?.distanceMeters, 300);
  });

  test("keeps showing the cached route when a recalculation fails", () async {
    final controller = container.read(
      navigationControllerProvider(_destination).notifier,
    );
    controller.onPositionUpdate(_origin);
    repo.pending[0].complete(_route(500));
    await Future<void>.value();

    controller.onPositionUpdate(_originMovedFar);
    repo.pending[1].completeError(const RouteFetchFailure("network blip"));
    await Future<void>.value();

    final state = container.read(navigationControllerProvider(_destination));
    expect(
      state.route?.distanceMeters,
      500,
      reason: "the prior good route survives a failed recalculation",
    );
    expect(state.isLoading, isFalse);
    expect(state.failure, isNull);
  });

  test("surfaces a failure only when there is no cached route yet", () async {
    final controller = container.read(
      navigationControllerProvider(_destination).notifier,
    );
    controller.onPositionUpdate(_origin);

    repo.pending.single.completeError(const RouteNotFoundFailure());
    await Future<void>.value();

    final state = container.read(navigationControllerProvider(_destination));
    expect(state.route, isNull);
    expect(state.failure, isA<RouteNotFoundFailure>());
    expect(state.isLoading, isFalse);
  });

  test("discards a superseded (stale) response — a late reply to an "
      "earlier request never overwrites a newer one", () async {
    final controller = container.read(
      navigationControllerProvider(_destination).notifier,
    );
    controller.onPositionUpdate(_origin); // fetch #1, left pending
    controller.onPositionUpdate(_originMovedFar); // fetch #2, supersedes #1

    expect(repo.callCount, 2);

    // fetch #2 resolves first.
    repo.pending[1].complete(_route(300));
    await Future<void>.value();
    expect(
      container
          .read(navigationControllerProvider(_destination))
          .route
          ?.distanceMeters,
      300,
    );

    // fetch #1's late reply must not overwrite fetch #2's result.
    repo.pending[0].complete(_route(999));
    await Future<void>.value();
    expect(
      container
          .read(navigationControllerProvider(_destination))
          .route
          ?.distanceMeters,
      300,
    );
  });

  test(
    "a different destination gets an independent, fresh controller — a "
    "fetch left in flight for one destination cannot populate another's "
    "state (the family key replaces the old imperative begin() reset)",
    () async {
      final firstController = container.read(
        navigationControllerProvider(_destination).notifier,
      );
      firstController.onPositionUpdate(_origin);
      final Completer<NavigationRoute> staleFetch = repo.pending.single;

      // A different destination — necessarily a different family member,
      // starting from its own fresh `build()` state.
      expect(
        container.read(navigationControllerProvider(_otherDestination)).route,
        isNull,
      );

      staleFetch.complete(_route(500));
      await Future<void>.value();

      expect(
        container.read(navigationControllerProvider(_otherDestination)).route,
        isNull,
        reason:
            "a fetch for a different destination must not populate this one",
      );
      expect(
        container
            .read(navigationControllerProvider(_destination))
            .route
            ?.distanceMeters,
        500,
        reason: "...but it does still resolve normally for its own destination",
      );
    },
  );
}
