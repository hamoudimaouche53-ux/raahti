import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "shared_preferences_provider.dart";

const String _themeModePrefsKey = "rahati.settings.theme_mode";
const String _localeLanguageCodePrefsKey = "rahati.settings.locale_language_code";

ThemeMode _themeModeFromPrefsValue(String? value) => switch (value) {
  "light" => ThemeMode.light,
  "dark" => ThemeMode.dark,
  _ => ThemeMode.system,
};

String _themeModeToPrefsValue(ThemeMode mode) => switch (mode) {
  ThemeMode.light => "light",
  ThemeMode.dark => "dark",
  ThemeMode.system => "system",
};

/// Theme mode (Light / Dark / System), consumed by `MaterialApp.router` in
/// lib/app.dart. Defaults to following the OS setting, per docs/design/
/// foundations.md §1 ("both are first-class, not a light-only design").
///
/// User-facing control is SCR-029 (Language & Theme Settings,
/// LanguageThemeSettingsScreen) via [setThemeMode]; the choice is persisted
/// through [sharedPreferencesProvider] so it survives app restarts
/// (US-06.1's "persists across sessions" requirement — the same discipline
/// applies here even though that requirement's own wording is about
/// language, per SCR-029's wireframe pairing the two settings together).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _themeModeFromPrefsValue(
    ref.watch(sharedPreferencesProvider)?.getString(_themeModePrefsKey),
  );

  void setThemeMode(ThemeMode mode) {
    state = mode;
    ref
        .read(sharedPreferencesProvider)
        ?.setString(_themeModePrefsKey, _themeModeToPrefsValue(mode));
  }
}

final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// App locale override (FR / EN / AR — ADR-0017). `null` means "follow the
/// device locale" — `MaterialApp.router`'s own default locale resolution
/// applies in that case (lib/app.dart passes this straight through as
/// `locale:`).
///
/// User-facing control is also SCR-029 (LanguageThemeSettingsScreen) via
/// [setLocale] — see [ThemeModeNotifier] doc for the persistence rationale.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final String? languageCode = ref
        .watch(sharedPreferencesProvider)
        ?.getString(_localeLanguageCodePrefsKey);
    return languageCode == null ? null : Locale(languageCode);
  }

  void setLocale(Locale? locale) {
    state = locale;
    final SharedPreferences? prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      prefs?.remove(_localeLanguageCodePrefsKey);
    } else {
      prefs?.setString(_localeLanguageCodePrefsKey, locale.languageCode);
    }
  }
}

final NotifierProvider<LocaleNotifier, Locale?> localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
