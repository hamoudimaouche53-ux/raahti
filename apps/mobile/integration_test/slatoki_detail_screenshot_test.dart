// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-02.1.4 (verified-mosque women's-section
// distinction, SCR-010 place detail) with real on-device rendering, using
// injected sample data via the same provider-override mechanism every
// screenshot test in this log has used since Feature 1 (no backend exists
// yet — ADR-0016 still open). Light/Dark/Arabic(RTL) are separate
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
import "package:rahati/features/slatoki/domain/entities/slatoki_place.dart";
import "package:rahati/features/slatoki/domain/entities/women_verification_level.dart";
import "package:rahati/features/slatoki/presentation/providers/slatoki_place_providers.dart";

const _center = Coordinates(latitude: 36.7538, longitude: 3.0588);

SlatokiPlace _place(
  String id,
  String nameFr, {
  required WomenVerificationLevel womenVerificationLevel,
}) => SlatokiPlace(
  place: Place(
    id: id,
    placeKind: PlaceKind.thirdPartyPlace,
    name: LocalizedText(fr: nameFr, ar: "مسجد $id", en: nameFr),
    position: _center,
    pinColor: PinColor.magenta,
    distanceMeters: 210,
    averageRating: 4.6,
    reviewCount: 24,
    isFree: true,
    tags: const ["prayer", "wudu"],
  ),
  womenVerificationLevel: womenVerificationLevel,
);

final _verifiedPlace = _place(
  "1",
  "Mosquée El Nour",
  womenVerificationLevel: WomenVerificationLevel.verifiedConfirmed,
);
final _genericPlace = _place(
  "2",
  "Mosquée El Fath",
  womenVerificationLevel: WomenVerificationLevel.generic,
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

Future<void> _openSlatokiTabAndTapFirstPlace(WidgetTester tester) async {
  await _settle(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text("Slatoki"),
    ),
  );
  await _settle(tester, seconds: 2);
  await tester.tap(find.text("Mosquée El Nour").hitTestable());
  await tester.pump();
  await _settle(tester, seconds: 1);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    "Light (FR): verified mosque — prominent 'Femmes — section confirmée' chip",
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
            slatokiPlacesProvider.overrideWith(
              (ref) async => [_verifiedPlace, _genericPlace],
            ),
          ],
          child: const RahatiApp(),
        ),
      );
      await _openSlatokiTabAndTapFirstPlace(tester);

      // ignore: avoid_print
      print("HOLD_START");
      await tester.pump(const Duration(seconds: 30));
    },
  );

  testWidgets("Dark (FR): generic mosque — neutral 'not confirmed' note", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(_DarkThemeModeNotifier.new),
          slatokiPlacesProvider.overrideWith(
            (ref) async => [_genericPlace, _verifiedPlace],
          ),
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
    await tester.tap(find.text("Mosquée El Fath").hitTestable());
    await tester.pump();
    await _settle(tester, seconds: 1);

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets("RTL (AR): verified mosque chip, mirrored", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
          localeProvider.overrideWith(_ArabicLocaleNotifier.new),
          slatokiPlacesProvider.overrideWith(
            (ref) async => [_verifiedPlace, _genericPlace],
          ),
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
    // Arabic name for id "1" is "مسجد 1".
    await tester.tap(find.text("مسجد 1").hitTestable());
    await tester.pump();
    await _settle(tester, seconds: 1);

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });
}
