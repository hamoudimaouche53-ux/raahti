// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — demonstrates EPIC-05's flagship screens (SCR-020 Profile
// Home, SCR-030 Sign In/Sign Up) with real on-device rendering. Run with
// `--dart-define=USE_MOCK_AUTH=true` so `MockAuthRepository`/
// `MockUserRepository`/`MockFavoriteRepository`/`MockVisitHistoryRepository`
// are wired (ADR-0023's established mock-adapter pattern, extended to
// EPIC-05 — see `AppEnv.useMockAuth`'s own doc comment).
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

Future<void> _settle(WidgetTester tester, {int seconds = 2}) async {
  for (int i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Splash (2s auto-advance) → Map → tap the Profile bottom-nav
/// destination → SCR-020. Deliberately **not** `pumpAndSettle()` anywhere
/// here — the Map branch stays mounted (`IndexedStack`) behind every
/// other branch and its real GPS position stream (US-01.1.6) keeps
/// ticking and scheduling frames in the background regardless of which
/// tab is visible, so `pumpAndSettle` never returns (same reasoning
/// `nav_shell_screenshot_test.dart`'s own doc comment already documents).
Future<void> _navigateToProfileHome(
  WidgetTester tester, {
  String profileTabLabel = "Profil",
}) async {
  await _settle(tester, seconds: 5);

  await tester.tap(find.text(profileTabLabel));
  await _settle(tester, seconds: 2);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Light (FR): SCR-020 Profile Home, guest state", (
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
    await _navigateToProfileHome(tester);

    // ignore: avoid_print
    print("HOLD_START");
    await _settle(tester, seconds: 30);
  });

  testWidgets(
    "Dark (FR): SCR-020 Profile Home, registered state (after signing in "
    "via SCR-030)",
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeProvider.overrideWith(_DarkThemeModeNotifier.new),
          ],
          child: const RahatiApp(),
        ),
      );
      await _navigateToProfileHome(tester);

      await tester.tap(find.text("Se connecter"));
      await _settle(tester, seconds: 2);
      await tester.enterText(
        find.byType(TextField).first,
        "amina.b@example.com",
      );
      await tester.enterText(find.byType(TextField).last, "password123");
      await tester.tap(find.text("Se connecter").last);
      await _settle(tester, seconds: 2);

      // ignore: avoid_print
      print("HOLD_START");
      await _settle(tester, seconds: 30);
    },
  );

  testWidgets(
    "RTL (AR): SCR-030 Sign In / Sign Up, mirrored",
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
      await _navigateToProfileHome(tester, profileTabLabel: "الملف الشخصي");

      await tester.tap(find.text("تسجيل الدخول").first);
      await _settle(tester, seconds: 2);

      // ignore: avoid_print
      print("HOLD_START");
      await _settle(tester, seconds: 30);
    },
  );
}
