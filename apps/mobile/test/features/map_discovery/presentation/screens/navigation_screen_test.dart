import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/route.dart";
import "package:rahati/features/map_discovery/domain/repositories/route_repository.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";
import "package:rahati/features/map_discovery/presentation/providers/route_providers.dart";
import "package:rahati/features/map_discovery/presentation/screens/navigation_screen.dart";
import "package:rahati/features/map_discovery/presentation/widgets/route_information_card.dart";
import "package:rahati/l10n/app_localizations.dart";

const _origin = Coordinates(latitude: 36.75, longitude: 3.06);
const _destination = Coordinates(latitude: 36.751, longitude: 3.061);

class _ImmediateRouteRepository implements RouteRepository {
  _ImmediateRouteRepository(this.route);

  final NavigationRoute route;
  int callCount = 0;

  @override
  Future<NavigationRoute> getWalkingRoute({
    required Coordinates origin,
    required Coordinates destination,
  }) async {
    callCount++;
    return route;
  }
}

Widget _wrap(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: RahatiTheme.light,
      locale: const Locale("fr"),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

void main() {
  testWidgets("fetches and shows the initial route immediately when "
      "userPositionStreamProvider already holds a resolved value before the "
      "screen mounts (regression — ref.listen/listenManual's fireImmediately "
      "must seed from the already-current value; a plain, non-immediate "
      "listener never fires for it since MapScreen keeps that provider warm "
      "and a stationary user produces no further GPS emission)", (
    tester,
  ) async {
    final route = const NavigationRoute(
      points: <Coordinates>[],
      distanceMeters: 500,
      durationSeconds: 300,
    );
    final repo = _ImmediateRouteRepository(route);

    final container = ProviderContainer(
      overrides: [
        userPositionStreamProvider.overrideWith(
          (ref) => Stream<Coordinates>.value(_origin),
        ),
        routeRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    // Warm `userPositionStreamProvider` to AsyncData *before* the screen
    // ever mounts — reproduces the real app's flow, where MapScreen has
    // already been watching this (non-autoDispose) provider. A plain
    // microtask flush (`Future.value()`, not `.delayed`) — `testWidgets`'
    // binding fakes real Timers, so `.delayed` never resolves without a
    // `tester.pump()` to drive it, but `Stream.value`'s subscription
    // resolves via the microtask queue alone.
    final sub = container.listen(userPositionStreamProvider, (_, _) {});
    await Future<void>.value();
    expect(container.read(userPositionStreamProvider).hasValue, isTrue);
    sub.close();

    await tester.pumpWidget(
      _wrap(
        container,
        const NavigationScreen(
          args: NavigationScreenArgs(
            destination: _destination,
            destinationLabel: "Test Destination",
          ),
        ),
      ),
    );
    // One pump to build+mount (registers the initState listener, which
    // must fire immediately for the value already in the provider) and a
    // second to let the resulting fetch's Future resolve.
    await tester.pump();
    await tester.pump();

    expect(
      repo.callCount,
      1,
      reason:
          "the initial route fetch must happen without any further GPS "
          "stream emission after the screen mounts",
    );
    expect(find.byType(RouteInformationCard), findsOneWidget);
  });
}
