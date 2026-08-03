// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-02.1.3 (Prayer/Wudu filter tabs + the real
// list they narrow) with real on-device rendering, using injected sample
// data via the same provider-override mechanism every screenshot test in
// this log has used since Feature 1 (no backend exists yet — ADR-0016
// still open). Light/Dark/Arabic(RTL) are separate `testWidgets` cases so
// each can be captured independently via external `adb exec-out
// screencap` while held.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/slatoki/domain/entities/slatoki_place.dart";
import "package:rahati/features/slatoki/domain/entities/women_verification_level.dart";
import "package:rahati/features/slatoki/presentation/providers/slatoki_place_providers.dart";

const _center = Coordinates(latitude: 36.7538, longitude: 3.0588);

SlatokiPlace _place(
  String id,
  String nameFr, {
  required List<String> tags,
  required double distanceMeters,
}) => SlatokiPlace(
  place: Place(
    id: id,
    placeKind: id == "1" ? PlaceKind.station : PlaceKind.thirdPartyPlace,
    name: LocalizedText(fr: nameFr, ar: "مكان $id", en: nameFr),
    position: _center,
    pinColor: PinColor.magenta,
    distanceMeters: distanceMeters,
    averageRating: 4.2,
    reviewCount: 8,
    isFree: true,
    tags: tags,
  ),
  womenVerificationLevel: id == "2"
      ? WomenVerificationLevel.verifiedConfirmed
      : WomenVerificationLevel.generic,
);

final _samplePlaces = [
  _place(
    "1",
    "Tente RAHETI Didouche",
    tags: const ["prayer"],
    distanceMeters: 90,
  ),
  _place(
    "2",
    "Mosquée El Nour",
    tags: const ["prayer", "wudu"],
    distanceMeters: 210,
  ),
  _place("3", "Mosquée El Fath", tags: const ["wudu"], distanceMeters: 340),
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

Future<void> _settle(WidgetTester tester, {int seconds = 4}) async {
  for (int i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): Slatoki tab, 'Prière seule' filter (default)", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          slatokiPlacesProvider.overrideWith((ref) async => _samplePlaces),
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
    await _settle(tester, seconds: 2);

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets("Dark (FR): 'Prière + Wudu' filter selected", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(_DarkThemeModeNotifier.new),
          slatokiPlacesProvider.overrideWith((ref) async => _samplePlaces),
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
    await _settle(tester, seconds: 2);
    await tester.tap(find.text("Prière + Wudu"));
    await tester.pump();
    await _settle(tester, seconds: 1);

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets("RTL (AR): filter tabs mirrored, 'Wudu seul' selected", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          localeProvider.overrideWith(_ArabicLocaleNotifier.new),
          slatokiPlacesProvider.overrideWith((ref) async => _samplePlaces),
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
    await _settle(tester, seconds: 2);
    await tester.tap(find.text("الوضوء فقط"));
    await tester.pump();
    await _settle(tester, seconds: 1);

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });
}
