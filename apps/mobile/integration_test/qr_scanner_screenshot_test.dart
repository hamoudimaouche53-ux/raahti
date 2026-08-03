// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-04.1 (SCR-013 QR Scanner) with real
// on-device rendering, including a genuine live camera feed (CAMERA
// permission pre-granted via `adb shell pm grant` before this test runs,
// so the OS permission dialog — a native dialog outside the Flutter
// widget tree — never blocks automation). Run with
// `--dart-define=USE_MOCK_PLACE_DETAIL=true` so `MockPlaceDetailRepository`
// (ADR-0023) supplies a station with a cabin, making the "Scanner le QR"
// entry point (US-04.1) appear on the place-detail sheet.
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
import "package:rahati/features/map_discovery/presentation/widgets/place_detail_sheet.dart";

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

class _DarkThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.dark;
}

class _ArabicLocaleNotifier extends LocaleNotifier {
  @override
  Locale? build() => const Locale("ar");
}

/// `_ScanTargetFrame`'s idle pulse is a perpetual `AnimationController`
/// loop — `pumpAndSettle()` never returns once SCR-013 is on screen, same
/// issue this log has solved the same way for Qibla's calibrating pulse
/// and the RAHETI tent's provider-override screenshots.
Future<void> _settle(WidgetTester tester, {int seconds = 3}) async {
  for (int i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> _navigateToScanner(
  WidgetTester tester, {
  String buttonText = "Scanner le QR",
}) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  await tester.tap(find.byType(PlaceMarker));
  await tester.pumpAndSettle(const Duration(seconds: 2));
  // Explicit real-time wait for MockPlaceDetailRepository's artificial
  // 400ms delay to resolve — `pumpAndSettle` alone can return before a
  // bare `Future.delayed` timer fires, since a pending Timer doesn't keep
  // a frame "scheduled" the way an ongoing animation does.
  await _settle(tester, seconds: 2);

  // The sheet's `initialChildSize: 0.5` viewport, on a real device, isn't
  // always tall enough to lay out (and thus build) the trailing action
  // buttons below the cabin list — `ListView`'s sliver delegate only
  // mounts children near the visible viewport, confirmed via a diagnostic
  // run (cabin rows found, but neither action button was). Scroll it into
  // view rather than assuming it's already built. Scoped to
  // `PlaceDetailSheet`'s own `Scrollable` — the map screen underneath has
  // its own (still-mounted) scrollables, so an unscoped
  // `find.byType(Scrollable)` matches more than one.
  await tester.scrollUntilVisible(
    find.text(buttonText),
    200,
    scrollable: find.descendant(
      of: find.byType(PlaceDetailSheet),
      matching: find.byType(Scrollable),
    ),
  );
  await _settle(tester, seconds: 1);

  await tester.tap(find.text(buttonText));
  await _settle(tester, seconds: 2);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): SCR-013 live camera scan view, permission "
      "granted", (tester) async {
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
    await _navigateToScanner(tester);

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });

  testWidgets("Dark (FR): SCR-013 manual-entry accessibility fallback "
      "dialog open", (tester) async {
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
    await _navigateToScanner(tester);

    await tester.tap(find.text("Saisir le code manuellement"));
    await _settle(tester, seconds: 1);

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });

  testWidgets("RTL (AR): SCR-013 live camera scan view, mirrored", (
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
    await _navigateToScanner(tester, buttonText: "مسح رمز QR");

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });
}
