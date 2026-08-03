// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-01.2.2 (real-time cabin status / declarative
// third-party status) and US-01.2.3 (tariff + payment methods) with real
// on-device rendering. Run with
// `--dart-define=USE_MOCK_PLACE_DETAIL=true` so `MockPlaceDetailRepository`
// (ADR-0023) is active and the mock-data banner is visible — same
// injected-sample-data honesty pattern as every other screenshot test in
// this log (no backend exists yet).
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

Place _thirdParty() => Place(
  id: "p1",
  placeKind: PlaceKind.thirdPartyPlace,
  name: const LocalizedText(
    fr: "Mosquée El Hidaya",
    ar: "مسجد الهداية",
    en: "El Hidaya Mosque",
  ),
  position: _center,
  pinColor: PinColor.green,
  distanceMeters: 240,
  averageRating: null,
  reviewCount: 0,
  isFree: true,
  tags: const ["prayer"],
);

// `List<dynamic>`, not `List<Override>` — `Override` isn't exported from
// `flutter_riverpod`'s public API surface in this version. Safe here
// because every call site spreads (`...`) this into a list literal passed
// directly as `ProviderScope(overrides: [...])`'s argument, which gets
// downward type inference from that parameter — each (dynamically-typed)
// element is checked/cast against `Override` in context and succeeds at
// runtime since it really is one.
List<dynamic> _positionOverrides() => [
  userPositionProvider.overrideWith((ref) async => _center),
  userPositionStreamProvider.overrideWith((ref) => Stream.value(_center)),
];

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

  testWidgets("Light (FR): station detail sheet with mock cabin status + "
      "tariff", (tester) async {
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

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets("Dark (FR): station detail sheet with mock cabin status", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_DarkThemeModeNotifier.new),
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

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets("RTL (AR): third-party place declarative status chip, mirrored", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._positionOverrides(),
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          localeProvider.overrideWith(_ArabicLocaleNotifier.new),
          nearbyPlacesProvider.overrideWith(
            () => _FakeNearbyPlacesNotifier(
              () async => PlacesSnapshot(
                places: [_thirdParty()],
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

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });
}
