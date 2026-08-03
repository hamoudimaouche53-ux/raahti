// Traces to: SCR-003, US-01.1.1, US-01.1.4, US-01.1.5, US-01.1.6, US-01.1.7,
// docs/design/wireframes/mobile-map-discovery.md#scr-003.
import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/location_failure.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/places_snapshot.dart";
import "package:rahati/features/map_discovery/domain/repositories/place_repository.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";
import "package:rahati/features/map_discovery/presentation/screens/map_screen.dart";
import "package:rahati/features/map_discovery/presentation/widgets/cluster_marker.dart";
import "package:rahati/features/map_discovery/presentation/widgets/place_detail_sheet.dart";
import "package:rahati/features/map_discovery/presentation/widgets/place_marker.dart";
import "package:rahati/features/map_discovery/presentation/widgets/recenter_fab.dart";
import "package:rahati/features/map_discovery/presentation/widgets/user_position_marker.dart";
import "package:rahati/l10n/app_localizations.dart";

import "../../../../support/fake_nearby_places_notifier.dart";

const _center = Coordinates(latitude: 36.75, longitude: 3.06);

Place _place(
  String id,
  PinColor color, {
  Coordinates position = _center,
  bool isFree = true,
  LocalizedText? name,
}) => Place(
  id: id,
  placeKind: PlaceKind.station,
  name: name ?? const LocalizedText(fr: "F", ar: "A", en: "E"),
  position: position,
  pinColor: color,
  distanceMeters: 100,
  averageRating: null,
  reviewCount: 0,
  isFree: isFree,
  tags: const <String>[],
);

PlacesSnapshot _snapshot(List<Place> places, {bool isFromCache = false}) =>
    PlacesSnapshot(
      places: places,
      lastSyncedAt: DateTime(2026, 7, 31, 12),
      isFromCache: isFromCache,
    );

/// Both providers resolve to [_center] — matches real behavior, where the
/// one-shot fetch ([userPositionProvider]) and the continuous stream
/// ([userPositionStreamProvider]) agree on the device's position.
///
/// `List<dynamic>`, not `List<Override>` — `Override` isn't exported from
/// `flutter_riverpod`'s public API surface in this version.
List<dynamic> _resolvedPositionOverrides([Coordinates coords = _center]) => [
  userPositionProvider.overrideWith((ref) async => coords),
  userPositionStreamProvider.overrideWith((ref) => Stream.value(coords)),
];

List<dynamic> _erroringPositionOverrides(Object error) => [
  userPositionProvider.overrideWith((ref) async => throw error),
  userPositionStreamProvider.overrideWith((ref) => Stream.error(error)),
];

/// Never resolves — keeps both providers in `AsyncValue.loading`, matching
/// the original `Completer`-based pending-state fixture.
List<dynamic> _pendingPositionOverrides() => [
  userPositionProvider.overrideWith((ref) => Completer<Coordinates>().future),
  userPositionStreamProvider.overrideWith(
    (ref) => StreamController<Coordinates>().stream,
  ),
];

dynamic _nearbyPlaces(Future<PlacesSnapshot> Function() build) =>
    nearbyPlacesProvider.overrideWith(() => FakeNearbyPlacesNotifier(build));

Widget _wrap(ProviderScope scope) {
  // `ProviderScope` must wrap `MaterialApp`, not sit inside its `home:` —
  // a route pushed later (e.g. `showModalBottomSheet`) attaches directly
  // under `Navigator`'s `Overlay`, a sibling of `home`'s subtree in the
  // element tree, not a descendant of it. A `ConsumerWidget` built inside
  // such a route (like `PlaceDetailSheet`'s `_PlaceDetailExtra`) would
  // otherwise fail with "No ProviderScope found". Re-wrapping here (using
  // the already-constructed `scope`'s own `overrides`/`child`) keeps every
  // call site's `_wrap(ProviderScope(overrides: ..., child: ...))` shape
  // unchanged.
  return ProviderScope(
    overrides: scope.overrides,
    child: MaterialApp(
      theme: RahatiTheme.light,
      locale: const Locale("fr"),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: scope.child,
    ),
  );
}

void main() {
  testWidgets("shows a loading banner while position is resolving", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ProviderScope(
          overrides: [
            ..._pendingPositionOverrides(),
            _nearbyPlaces(() => Completer<PlacesSnapshot>().future),
          ],
          child: const MapScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey("position-loading")), findsOneWidget);
    expect(find.byType(UserPositionMarker), findsNothing);
  });

  testWidgets(
    "shows the user marker and a single place marker once both resolve, "
    "with no error banners",
    (tester) async {
      // A single place — deliberately avoids asserting on flutter_map's
      // own viewport-culling behavior for multiple markers (that is
      // flutter_map's concern, not this app's code); multi-place
      // clustering behavior is covered by the two tests below and by
      // place_clusterer_test.dart's deterministic, rendering-independent
      // unit tests.
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(
                () async => _snapshot([_place("1", PinColor.green)]),
              ),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(UserPositionMarker), findsOneWidget);
      expect(find.byType(PlaceMarker), findsOneWidget);
      expect(find.byType(ClusterMarker), findsNothing);
      expect(find.byKey(const ValueKey("position-error")), findsNothing);
      expect(find.byKey(const ValueKey("places-error")), findsNothing);
    },
  );

  testWidgets("clusters two places at the exact same position into one "
      "ClusterMarker (US-01.1.2)", (tester) async {
    await tester.pumpWidget(
      _wrap(
        ProviderScope(
          overrides: [
            ..._resolvedPositionOverrides(),
            _nearbyPlaces(
              () async => _snapshot([
                _place("1", PinColor.green),
                _place("2", PinColor.magenta),
              ]),
            ),
          ],
          child: const MapScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ClusterMarker), findsOneWidget);
    expect(find.byType(PlaceMarker), findsNothing);
    expect(find.text("2"), findsOneWidget);
  });

  testWidgets(
    "a single place marker's tap target is 48x48dp, not its 32x32dp "
    "visual pin (US-06.4 — component-library.md's 48dp minimum)",
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(
                () async => _snapshot([_place("1", PinColor.green)]),
              ),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.getSize(find.byType(PlaceMarker)), const Size(48, 48));
    },
  );

  testWidgets(
    "a cluster marker's tap target is 48x48dp regardless of its "
    "count-dependent visual diameter (US-06.4 — component-library.md's "
    "48dp minimum)",
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(
                () async => _snapshot([
                  _place("1", PinColor.green),
                  _place("2", PinColor.magenta),
                ]),
              ),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.getSize(find.byType(ClusterMarker)), const Size(48, 48));
    },
  );

  testWidgets(
    "shows a specific permission-denied banner and no places-error banner "
    "when position fails (avoids a redundant second banner)",
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._erroringPositionOverrides(
                const LocationPermissionDeniedFailure(),
              ),
              _nearbyPlaces(
                () async => throw const LocationPermissionDeniedFailure(),
              ),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey("position-error")), findsOneWidget);
      expect(find.byKey(const ValueKey("places-error")), findsNothing);
      expect(
        find.textContaining("Autorisation de localisation refusée"),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "shows a specific 'no backend configured' banner when places fail but "
    "position succeeds",
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(() async => throw const ApiNotConfiguredFailure()),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(UserPositionMarker), findsOneWidget);
      expect(find.byKey(const ValueKey("places-error")), findsOneWidget);
      expect(find.textContaining("Aucun serveur configuré"), findsOneWidget);
    },
  );

  testWidgets("tapping a place marker opens the PlaceDetailSheet (US-01.1.3)", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ProviderScope(
          overrides: [
            ..._resolvedPositionOverrides(),
            _nearbyPlaces(() async => _snapshot([_place("1", PinColor.green)])),
          ],
          child: const MapScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(PlaceDetailSheet), findsNothing);
    await tester.tap(find.byType(PlaceMarker));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceDetailSheet), findsOneWidget);
  });

  testWidgets(
    "typing a settled search query narrows a cluster down to a single "
    "place marker (US-01.1.4)",
    (tester) async {
      // Both places share one position (the established pattern for
      // deterministic marker-count widget tests — see place_clusterer_test.dart
      // and this file's "clusters two places..." test above; flutter_map's
      // own viewport culling makes asserting on multiple *separated*
      // un-clustered markers unreliable in a widget test).
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(
                () async => _snapshot([
                  _place(
                    "1",
                    PinColor.green,
                    name: const LocalizedText(
                      fr: "Station Didouche",
                      ar: "أ",
                      en: "Didouche",
                    ),
                  ),
                  _place(
                    "2",
                    PinColor.blue,
                    name: const LocalizedText(
                      fr: "Toilettes Hydra",
                      ar: "ب",
                      en: "Hydra",
                    ),
                  ),
                ]),
              ),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(ClusterMarker), findsOneWidget);

      await tester.enterText(find.byType(TextField), "didouche");
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(ClusterMarker), findsNothing);
      expect(find.byType(PlaceMarker), findsOneWidget);
    },
  );

  testWidgets(
    "selecting the 'Payant' category chip narrows a cluster down to a "
    "single place marker (US-01.1.5)",
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(
                () async => _snapshot([
                  _place("1", PinColor.green, isFree: true),
                  _place("2", PinColor.blue, isFree: false),
                ]),
              ),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(ClusterMarker), findsOneWidget);

      await tester.tap(find.text("Payant"));
      await tester.pump();

      expect(find.byType(ClusterMarker), findsNothing);
      expect(find.byType(PlaceMarker), findsOneWidget);
    },
  );

  testWidgets(
    "search and category filters compose (AND) rather than override each "
    "other",
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(
                () async => _snapshot([
                  _place(
                    "1",
                    PinColor.green,
                    isFree: true,
                    name: const LocalizedText(
                      fr: "Alger Centre",
                      ar: "أ",
                      en: "E",
                    ),
                  ),
                  _place(
                    "2",
                    PinColor.blue,
                    isFree: false,
                    name: const LocalizedText(
                      fr: "Alger Centre",
                      ar: "أ",
                      en: "E",
                    ),
                  ),
                  _place(
                    "3",
                    PinColor.green,
                    isFree: true,
                    name: const LocalizedText(fr: "Hydra", ar: "ب", en: "F"),
                  ),
                ]),
              ),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text("Gratuit"));
      await tester.pump();
      await tester.enterText(find.byType(TextField), "alger");
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(PlaceMarker), findsOneWidget);
    },
  );

  testWidgets(
    "shows a 'no results' message when the active filter matches nothing, "
    "and hides it once cleared",
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(
                () async => _snapshot([_place("1", PinColor.green)]),
              ),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(TextField), "no such place");
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byKey(const ValueKey("filter-no-results")), findsOneWidget);
      expect(find.byType(PlaceMarker), findsNothing);

      await tester.tap(find.text("Tout"));
      await tester.pump();

      expect(find.byKey(const ValueKey("filter-no-results")), findsNothing);
      expect(find.byType(PlaceMarker), findsOneWidget);
    },
  );

  testWidgets(
    "filtering does not recreate the map's MapController (camera position "
    "is preserved across filter changes)",
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(
                () async => _snapshot([
                  _place("1", PinColor.green),
                  _place("2", PinColor.blue),
                ]),
              ),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final MapController before = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!;

      await tester.tap(find.text("Gratuit"));
      await tester.pump();

      final MapController after = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!;

      expect(identical(before, after), isTrue);
    },
  );

  group("recenter FAB (US-01.1.6)", () {
    testWidgets("shows locked (tracking) by default", (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(() async => _snapshot(const [])),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final RecenterFab fab = tester.widget(find.byType(RecenterFab));
      expect(fab.isLocked, isTrue);
    });

    testWidgets("a manual pan gesture unlocks tracking", (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(() async => _snapshot(const [])),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.drag(find.byType(FlutterMap), const Offset(-80, -80));
      await tester.pump();

      final RecenterFab fab = tester.widget(find.byType(RecenterFab));
      expect(fab.isLocked, isFalse);
    });

    testWidgets("tapping the FAB re-locks tracking", (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(() async => _snapshot(const [])),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.drag(find.byType(FlutterMap), const Offset(-80, -80));
      await tester.pump();
      expect(
        tester.widget<RecenterFab>(find.byType(RecenterFab)).isLocked,
        isFalse,
      );

      await tester.tap(find.byType(RecenterFab));
      await tester.pump();

      expect(
        tester.widget<RecenterFab>(find.byType(RecenterFab)).isLocked,
        isTrue,
      );
    });
  });

  group("offline cache (US-01.1.7)", () {
    testWidgets("shows the offline banner and dims markers when served from "
        "cache", (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(
                () async =>
                    _snapshot([_place("1", PinColor.green)], isFromCache: true),
              ),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey("offline-cache")), findsOneWidget);
      expect(find.byType(PlaceMarker), findsOneWidget);

      final Opacity opacity = tester.widget(
        find.ancestor(
          of: find.byType(PlaceMarker),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.85);
    });

    testWidgets("does not show the offline banner for a live fetch", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProviderScope(
            overrides: [
              ..._resolvedPositionOverrides(),
              _nearbyPlaces(
                () async => _snapshot([_place("1", PinColor.green)]),
              ),
            ],
            child: const MapScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey("offline-cache")), findsNothing);
      expect(
        find.ancestor(
          of: find.byType(PlaceMarker),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });
  });
}
