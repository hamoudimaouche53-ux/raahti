/// `User.preferred_language` — ERD §3.6 (base `fr`/`ar`), extended to
/// include `en` per the Phase 2 addendum (ADR-0017's trilingual support).
///
/// Deliberately **not** the same type the app's actual UI language is
/// driven by — `core/providers/app_settings_providers.dart`'s
/// `localeProvider` uses a plain `Locale` and is the one live mechanism
/// for switching the running app's language (SCR-029, EPIC-06, not yet
/// built). This enum only models the *persisted account preference* field
/// on [AppUser] — `SCR-020`'s account summary reads it, nothing writes to
/// the live `localeProvider` from it (that wiring is SCR-029's job).
enum LanguagePreference {
  fr,
  ar,
  en;

  static LanguagePreference fromWireValue(String value) {
    return LanguagePreference.values.firstWhere(
      (v) => v.name == value,
      orElse: () => LanguagePreference.fr,
    );
  }
}
