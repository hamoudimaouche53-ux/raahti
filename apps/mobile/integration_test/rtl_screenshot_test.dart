// Diagnostic-only helper — NOT part of the shipped app or the permanent
// test suite — used once to hold the app on-screen with the Arabic locale
// forced via the real `localeProvider` override mechanism (the same
// provider SCR-029's future language switcher will drive), so an external
// `adb exec-out screencap` can capture a genuine on-device RTL screenshot.
// Android's own locale broadcast requires system/root privileges not
// available via plain `adb shell` (see docs/phase-3-implementation-log.md),
// so this app-level override is the reliable path — not a fake/mocked UI,
// the real widget tree in the real app process.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:rahati/app.dart";
import "package:rahati/core/providers/app_settings_providers.dart";

class _ArabicLocaleNotifier extends LocaleNotifier {
  @override
  Locale? build() => const Locale("ar");
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    "hold the app on the Arabic locale for external screenshot capture",
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localeProvider.overrideWith(_ArabicLocaleNotifier.new)],
          child: const RahatiApp(),
        ),
      );
      // SplashScreen auto-advances to Map after 2s.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Hold on Map (Arabic/RTL) long enough for an external `adb screencap`.
      await tester.pump(const Duration(seconds: 20));
    },
  );
}
