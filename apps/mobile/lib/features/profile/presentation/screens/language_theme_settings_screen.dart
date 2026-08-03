import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/providers/app_settings_providers.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";

/// SCR-029 — Language & Theme Settings (US-06.1, US-06.5).
///
/// Selection changes apply immediately (no separate "save" step) — both
/// [themeModeProvider] and [localeProvider] are watched directly by
/// `RahatiApp` (lib/app.dart), so writing to either Notifier here
/// re-renders the whole app in place, preserving navigation position, per
/// docs/design/user-flows.md §6.
///
/// The three language option labels (Français/العربية/English) are
/// deliberately hard-coded literals, not routed through [AppLocalizations]
/// — per the wireframe's own accessibility note
/// (docs/design/wireframes/mobile-profile-account.md#scr-029), each
/// language name is written in its own script regardless of the *active*
/// locale (a French speaker must still see "العربية", not a translated
/// "Arabe"). This is the one intentional exception to this codebase's
/// otherwise-strict "never hard-code UI text" rule — flagged explicitly
/// here since that exact mistake (hard-coded text that should have been
/// localized) was a recurring bug in earlier features.
class LanguageThemeSettingsScreen extends ConsumerWidget {
  const LanguageThemeSettingsScreen({super.key});

  static const List<(String languageCode, String label)> _languageOptions =
      [
        ("fr", "Français"),
        ("ar", "العربية"),
        ("en", "English"),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale? localeOverride = ref.watch(localeProvider);
    // The language Radio list always shows one selection, even when no
    // override is set yet — the currently *resolved* locale (device
    // default) is the honest representation of "what's active right now".
    final String selectedLanguageCode =
        localeOverride?.languageCode ?? Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.languageThemeSettingsTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RahatiSpacing.space4,
                RahatiSpacing.space4,
                RahatiSpacing.space4,
                RahatiSpacing.space2,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.languageThemeSettingsLanguageSectionLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            RadioGroup<String>(
              groupValue: selectedLanguageCode,
              onChanged: (languageCode) {
                if (languageCode != null) {
                  ref.read(localeProvider.notifier).setLocale(Locale(languageCode));
                }
              },
              child: Column(
                children: <Widget>[
                  for (final (languageCode, label) in _languageOptions)
                    RadioListTile<String>(
                      value: languageCode,
                      title: Text(label),
                    ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                RahatiSpacing.space4,
                RahatiSpacing.space4,
                RahatiSpacing.space4,
                RahatiSpacing.space2,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.languageThemeSettingsThemeSectionLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RahatiSpacing.space4,
              ),
              child: SegmentedButton<ThemeMode>(
                segments: <ButtonSegment<ThemeMode>>[
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text(l10n.languageThemeSettingsThemeLight),
                    icon: const Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text(l10n.languageThemeSettingsThemeDark),
                    icon: const Icon(Icons.dark_mode_outlined),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text(l10n.languageThemeSettingsThemeSystem),
                    icon: const Icon(Icons.smartphone_outlined),
                  ),
                ],
                selected: <ThemeMode>{themeMode},
                onSelectionChanged: (selection) =>
                    ref.read(themeModeProvider.notifier).setThemeMode(selection.first),
              ),
            ),
            const SizedBox(height: RahatiSpacing.space6),
          ],
        ),
      ),
    );
  }
}
