// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-02.1.2 (Qibla compass, compact widget +
// full-screen) with real on-device rendering: real GPS position, real
// magnetometer readings via `flutter_compass` (ADR-0025), nothing
// injected. Light/Dark/Arabic(RTL) are separate `testWidgets` cases so
// each can be captured independently via external `adb exec-out
// screencap` while held.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/features/slatoki/presentation/widgets/qibla_compass.dart";

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

/// Bounded settle, deliberately not `pumpAndSettle()` — see
/// nav_shell_screenshot_test.dart's `_settle` doc comment. Doubly true
/// here: a real device's magnetometer emits continuously for as long as
/// the app is calibrating, which would never let `pumpAndSettle` converge.
Future<void> _settle(WidgetTester tester, {int seconds = 4}) async {
  for (int i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): Slatoki tab with the compact Qibla widget card", (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
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
    "Dark (FR): Qibla full-screen — real magnetometer needle, degree readout",
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeProvider.overrideWith(_DarkThemeModeNotifier.new),
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
      await tester.tap(find.byType(QiblaCompass));
      await _settle(tester, seconds: 3);

      // ignore: avoid_print
      print("HOLD_START");
      await tester.pump(const Duration(seconds: 30));
    },
  );

  testWidgets(
    "RTL (AR): Qibla full-screen — chrome mirrored, compass rose does not",
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeProvider.overrideWith(_LightThemeModeNotifier.new),
            localeProvider.overrideWith(_ArabicLocaleNotifier.new),
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
      await tester.tap(find.byType(QiblaCompass));
      await _settle(tester, seconds: 3);

      // ignore: avoid_print
      print("HOLD_START");
      await tester.pump(const Duration(seconds: 30));
    },
  );
}
