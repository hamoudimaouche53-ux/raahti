// Traces to: ADR-0018 (foundation), SCR-029 (LanguageThemeSettingsScreen,
// the real consumer of these providers as of EPIC-06 —
// docs/design/wireframes/mobile-profile-account.md#scr-029).
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/core/providers/shared_preferences_provider.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  group("themeModeProvider", () {
    test("defaults to ThemeMode.system without a SharedPreferences override "
        "(mirrors every existing widget test that pumps RahatiApp without "
        "calling bootstrapSharedPreferences)", () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test("setThemeMode updates the state", () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test(
      "setThemeMode persists via SharedPreferences, and a fresh "
      "Notifier reads the persisted value back (US-06.1's 'persists "
      "across sessions' requirement)",
      () async {
        SharedPreferences.setMockInitialValues({});
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        final ProviderContainer writer = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        writer.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
        writer.dispose();

        final ProviderContainer reader = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(reader.dispose);
        expect(reader.read(themeModeProvider), ThemeMode.dark);
      },
    );
  });

  group("localeProvider", () {
    test("defaults to null (follow device locale) without a "
        "SharedPreferences override", () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(localeProvider), isNull);
    });

    test("setLocale overrides the app locale", () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).setLocale(const Locale("ar"));
      expect(container.read(localeProvider), const Locale("ar"));
    });

    test(
      "setLocale persists via SharedPreferences, and a fresh Notifier "
      "reads the persisted value back",
      () async {
        SharedPreferences.setMockInitialValues({});
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        final ProviderContainer writer = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        writer.read(localeProvider.notifier).setLocale(const Locale("ar"));
        writer.dispose();

        final ProviderContainer reader = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(reader.dispose);
        expect(reader.read(localeProvider), const Locale("ar"));
      },
    );

    test(
      "setLocale(null) clears the persisted override so a fresh Notifier "
      "falls back to null (follow device locale) again",
      () async {
        SharedPreferences.setMockInitialValues({});
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        final ProviderContainer writer = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        writer.read(localeProvider.notifier).setLocale(const Locale("ar"));
        writer.read(localeProvider.notifier).setLocale(null);
        writer.dispose();

        final ProviderContainer reader = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(reader.dispose);
        expect(reader.read(localeProvider), isNull);
      },
    );
  });
}
