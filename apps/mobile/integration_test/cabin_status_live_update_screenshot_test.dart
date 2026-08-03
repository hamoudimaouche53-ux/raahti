// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-04.5 (FR-PAY-05, live cabin-occupancy
// updates) with real on-device rendering. `MockCabinRealtimeRepository`
// (below `AppEnv.useMockPlaceDetail`, same flag as
// `MockPlaceDetailRepository` — see that class's doc comment) flips the
// mock paid cabin (`s1-cabin-2`) between `occupied`/`free` every 4s — no
// real Supabase project exists yet (ADR-0016 still open) to demonstrate
// this against.
//
// Unlike every other screenshot test in this log, this one is captured
// as a **before/after pair from the same held-open screen**, not a
// Light/Dark/RTL triad — the dimension this story actually changes is
// time (does the status update without navigating away?), not
// theme/locale (already proven for `CabinStatusIndicator` back in
// Feature 6's own screenshots). Two `adb screencap`s are taken during
// this single test's hold window, a few seconds apart, straddling one of
// `MockCabinRealtimeRepository`'s 4s toggles.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/places_snapshot.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";
import "package:rahati/features/map_discovery/presentation/widgets/place_marker.dart";

class _FakeNearbyPlacesNotifier extends NearbyPlacesNotifier {
  _FakeNearbyPlacesNotifier(this._build);
  final Future<PlacesSnapshot> Function() _build;

  @override
  Future<PlacesSnapshot> build() => _build();
}

const _center = Coordinates(latitude: 36.7538, longitude: 3.0588);

Place _station() => Place(
  id: "s1",
  placeKind: PlaceKind.station,
  name: const LocalizedText(
    fr: "Station Didouche",
    ar: "محطة ديدوش",
    en: "Didouche Station",
  ),
  position: _center,
  pinColor: PinColor.amber,
  distanceMeters: 180,
  averageRating: 4.6,
  reviewCount: 32,
  isFree: false,
  tags: const ["women_confirmed", "wudu"],
);

List<dynamic> _positionOverrides() => [
  userPositionProvider.overrideWith((ref) async => _center),
  userPositionStreamProvider.overrideWith((ref) => Stream.value(_center)),
];

class _LightThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.light;
}

Future<void> _settle(WidgetTester tester, {int seconds = 3}) async {
  for (int i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): cabin-2 occupancy flips live in the open sheet", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          nearbyPlacesProvider.overrideWith(
            () => _FakeNearbyPlacesNotifier(
              () async => PlacesSnapshot(
                places: [_station()],
                lastSyncedAt: DateTime.now(),
                isFromCache: false,
              ),
            ),
          ),
        ],
        child: const RahatiApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byType(PlaceMarker));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _settle(tester, seconds: 2);

    // ignore: avoid_print
    print("HOLD_START");
    // Holds well past several of MockCabinRealtimeRepository's 4s
    // toggles — the external adb captures (before/after pair) happen
    // during this window, not driven by this test's own code.
    await _settle(tester, seconds: 60);
  });
}
