// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-02.1.5 (RAHETI Slatoki tent status card,
// list row + SCR-010 embed) with real on-device rendering, using injected
// sample data via the same provider-override mechanism every screenshot
// test in this log has used since Feature 1 (no backend exists yet —
// ADR-0016 still open). Light/Dark/Arabic(RTL) are separate `testWidgets`
// cases so each can be captured independently via external `adb exec-out
// screencap` while held.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/features/map_discovery/domain/entities/cabin.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/slatoki_tent.dart";
import "package:rahati/features/map_discovery/domain/entities/station_detail.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_detail_providers.dart";
import "package:rahati/features/slatoki/domain/entities/slatoki_place.dart";
import "package:rahati/features/slatoki/domain/entities/women_verification_level.dart";
import "package:rahati/features/slatoki/presentation/providers/slatoki_place_providers.dart";

const _center = Coordinates(latitude: 36.7538, longitude: 3.0588);

final _tentPlace = SlatokiPlace(
  place: Place(
    id: "s1",
    placeKind: PlaceKind.station,
    name: const LocalizedText(
      fr: "Tente RAHETI Didouche",
      ar: "خيمة راهتي ديدوش",
      en: "RAHETI Tent Didouche",
    ),
    position: _center,
    pinColor: PinColor.amber,
    distanceMeters: 90,
    averageRating: null,
    reviewCount: 0,
    isFree: true,
    tags: const ["prayer", "wudu"],
  ),
  womenVerificationLevel: WomenVerificationLevel.generic,
);

final _mosquePlace = SlatokiPlace(
  place: Place(
    id: "m1",
    placeKind: PlaceKind.thirdPartyPlace,
    name: const LocalizedText(
      fr: "Mosquée El Nour",
      ar: "مسجد النور",
      en: "El Nour Mosque",
    ),
    position: _center,
    pinColor: PinColor.magenta,
    distanceMeters: 210,
    averageRating: 4.6,
    reviewCount: 24,
    isFree: true,
    tags: const ["prayer", "wudu"],
  ),
  womenVerificationLevel: WomenVerificationLevel.verifiedConfirmed,
);

final _tentStationDetail = StationDetail(
  summary: _tentPlace.place,
  configuration: StationConfiguration.mobile,
  status: StationOperationalStatus.active,
  cabins: const <Cabin>[],
  slatokiTent: const SlatokiTent(
    deploymentStatus: DeploymentStatus.deployed,
    matCapacity: 4,
    hasLighting: true,
    hasPrivacyCurtain: true,
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

Future<void> _settle(WidgetTester tester, {int seconds = 4}) async {
  for (int i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

// `List<dynamic>`, not `List<Override>` — `Override` isn't exported from
// `flutter_riverpod`'s public API surface in this version (same caveat as
// nav_shell_screenshot_test.dart and others in this integration_test dir).
List<dynamic> _sampleDataOverrides() => [
  slatokiPlacesProvider.overrideWith((ref) async => [_tentPlace, _mosquePlace]),
  stationDetailProvider("s1").overrideWith((ref) async => _tentStationDetail),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): Slatoki tab list — RAHETI tent card + mosque row", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          ..._sampleDataOverrides(),
        ],
        child: const RahatiApp(),
      ),
    );
    await _settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text("Slatoki"),
      ),
    );
    await _settle(tester, seconds: 3);

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets(
    "Dark (FR): tent detail sheet — full SlatokiTentStatusCard embedded",
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeProvider.overrideWith(_DarkThemeModeNotifier.new),
            ..._sampleDataOverrides(),
          ],
          child: const RahatiApp(),
        ),
      );
      await _settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text("Slatoki"),
        ),
      );
      await _settle(tester, seconds: 3);
      await tester.tap(find.text("Tente RAHETI Didouche").hitTestable());
      await tester.pump();
      await _settle(tester, seconds: 2);

      // ignore: avoid_print
      print("HOLD_START");
      await tester.pump(const Duration(seconds: 30));
    },
  );

  testWidgets("RTL (AR): tent detail sheet, mirrored", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          localeProvider.overrideWith(_ArabicLocaleNotifier.new),
          ..._sampleDataOverrides(),
        ],
        child: const RahatiApp(),
      ),
    );
    await _settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text("Slatoki"),
      ),
    );
    await _settle(tester, seconds: 3);
    await tester.tap(find.text("خيمة راهتي ديدوش").hitTestable());
    await tester.pump();
    await _settle(tester, seconds: 2);

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });
}
