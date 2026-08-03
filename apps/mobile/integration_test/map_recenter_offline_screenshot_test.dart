// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-01.1.6 (recenter FAB, lock/unlock) and
// US-01.1.7 (offline cache + freshness indicator) with real on-device
// rendering, using injected sample data via the same provider-override
// mechanism the widget tests use (no backend exists yet — see
// docs/phase-3-implementation-log.md). Light/Dark/Arabic(RTL) are separate
// `testWidgets` cases so each can be captured independently via external
// `adb exec-out screencap` while held.
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

class _FakeNearbyPlacesNotifier extends NearbyPlacesNotifier {
  _FakeNearbyPlacesNotifier(this._build);
  final Future<PlacesSnapshot> Function() _build;

  @override
  Future<PlacesSnapshot> build() => _build();
}

const _center = Coordinates(latitude: 36.7538, longitude: 3.0588);

Place _place(String id, PlaceKind kind, PinColor color, String name) => Place(
  id: id,
  placeKind: kind,
  name: LocalizedText(fr: name, ar: "مكان $id", en: name),
  position: _center,
  pinColor: color,
  distanceMeters: 120 + (int.parse(id) * 40),
  averageRating: 4.2,
  reviewCount: 12,
  isFree: true,
  tags: const <String>[],
);

final _samplePlaces = [
  _place("1", PlaceKind.station, PinColor.amber, "Station Didouche"),
  _place("2", PlaceKind.thirdPartyPlace, PinColor.green, "WC Gratuit Hydra"),
];

// `List<dynamic>`/`dynamic`, not `List<Override>`/`Override` — `Override`
// isn't exported from `flutter_riverpod`'s public API surface in this
// version.
List<dynamic> _positionOverrides() => [
  userPositionProvider.overrideWith((ref) async => _center),
  userPositionStreamProvider.overrideWith((ref) => Stream.value(_center)),
];

dynamic _liveNearbyPlacesOverride() => nearbyPlacesProvider.overrideWith(
  () => _FakeNearbyPlacesNotifier(
    () async => PlacesSnapshot(
      places: _samplePlaces,
      lastSyncedAt: DateTime.now(),
      isFromCache: false,
    ),
  ),
);

dynamic _offlineNearbyPlacesOverride() => nearbyPlacesProvider.overrideWith(
  () => _FakeNearbyPlacesNotifier(
    () async => PlacesSnapshot(
      places: _samplePlaces,
      lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 7)),
      isFromCache: true,
    ),
  ),
);

class _LightThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.light;
}

class _DarkThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.dark;
}

class _ArabicLocaleNotifier extends LocaleNotifier {
  @override
  Locale? build() => const Locale("ar");
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): recenter FAB (locked) with live data", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          _liveNearbyPlacesOverride(),
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
        ],
        child: const RahatiApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets("Dark (FR): offline banner, dimmed cached pins, recenter FAB", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          _offlineNearbyPlacesOverride(),
          themeModeProvider.overrideWith(_DarkThemeModeNotifier.new),
        ],
        child: const RahatiApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets(
    "RTL (AR): recenter FAB mirrored to the start (left) edge with live data",
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._positionOverrides(),
            _liveNearbyPlacesOverride(),
            themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
            localeProvider.overrideWith(_ArabicLocaleNotifier.new),
          ],
          child: const RahatiApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ignore: avoid_print
      print("HOLD_START");
      await tester.pump(const Duration(seconds: 30));
    },
  );
}
