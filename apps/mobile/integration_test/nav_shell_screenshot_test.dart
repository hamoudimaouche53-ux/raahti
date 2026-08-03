// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates US-02.1.1 (4-destination bottom nav shell +
// Slatoki tab) with real on-device rendering. No sample-data overrides are
// needed: the Map branch (still the app's initial destination via Splash's
// existing auto-navigate timer) renders exactly as it did in EPIC-01 —
// real device GPS, honest "no server configured" banner (no backend
// deployed yet) — before each case switches to the branch under test.
// Light/Dark/Arabic(RTL) are separate `testWidgets` cases so each can be
// captured independently via external `adb exec-out screencap` while held.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";

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

/// Bounded settle, deliberately **not** `pumpAndSettle()`: the Map branch
/// stays mounted (`IndexedStack`) behind every other branch, so its real
/// GPS position stream (US-01.1.6) keeps ticking and scheduling frames in
/// the background regardless of which tab is visible — `pumpAndSettle`
/// would wait for that to stop, which it never does by design. A fixed
/// number of bounded pumps is enough for the splash timer, the nav
/// destination swap, and the page-transition animation to render.
Future<void> _settle(WidgetTester tester, {int seconds = 4}) async {
  for (int i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): Slatoki tab selected, bottom nav visible", (
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

    // Scoped to NavigationBar, not a bare find.text("Slatoki") — caught by
    // this test itself: the Map screen (US-01.1.5) already has its own
    // "Slatoki" category filter chip, so an unscoped finder ambiguously
    // matches both. Real users are unaffected (real taps hit coordinates,
    // not text), but the finder needs disambiguating.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text("Slatoki"),
      ),
    );
    await _settle(tester, seconds: 1);

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets(
    "Dark (FR): Emergency placeholder selected — 'Coming in V1.1' (ADR-0024)",
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

      await tester.tap(find.text("Urgence"));
      await _settle(tester, seconds: 1);

      // ignore: avoid_print
      print("HOLD_START");
      await tester.pump(const Duration(seconds: 30));
    },
  );

  testWidgets("RTL (AR): Slatoki tab selected, bottom nav order stays fixed", (
    tester,
  ) async {
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
    await _settle(tester, seconds: 1);

    // ignore: avoid_print
    print("HOLD_START");
    await tester.pump(const Duration(seconds: 30));
  });
}
