// Traces to: SCR-029 (US-06.1, US-06.5) —
// docs/design/wireframes/mobile-profile-account.md#scr-029.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/providers/app_settings_providers.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/profile/presentation/screens/language_theme_settings_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Locale locale = const Locale("fr"),
}) async {
  final ProviderContainer container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: RahatiTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const LanguageThemeSettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    "shows the AppBar title and both section labels",
    (tester) async {
      await _pump(tester);

      expect(find.text("Langue et thème"), findsOneWidget);
      expect(find.text("Langue"), findsOneWidget);
      expect(find.text("Thème"), findsOneWidget);
    },
  );

  testWidgets(
    "shows the 3 language options in their own script, not translated",
    (tester) async {
      await _pump(tester);

      expect(find.text("Français"), findsOneWidget);
      expect(find.text("العربية"), findsOneWidget);
      expect(find.text("English"), findsOneWidget);
    },
  );

  testWidgets(
    "with no override, the resolved locale (fr) is the selected radio, "
    "and 'Système' is the selected theme segment",
    (tester) async {
      await _pump(tester);

      final RadioGroup<String> group = tester.widget<RadioGroup<String>>(
        find.byType(RadioGroup<String>),
      );
      expect(group.groupValue, "fr");

      final SegmentedButton<ThemeMode> segmented = tester
          .widget<SegmentedButton<ThemeMode>>(
            find.byType(SegmentedButton<ThemeMode>),
          );
      expect(segmented.selected, <ThemeMode>{ThemeMode.system});
    },
  );

  testWidgets(
    "tapping 'العربية' sets localeProvider to Locale('ar')",
    (tester) async {
      final ProviderContainer container = await _pump(tester);

      await tester.tap(find.text("العربية"));
      await tester.pumpAndSettle();

      expect(container.read(localeProvider), const Locale("ar"));
    },
  );

  testWidgets(
    "tapping the 'Sombre' segment sets themeModeProvider to ThemeMode.dark",
    (tester) async {
      final ProviderContainer container = await _pump(tester);

      await tester.tap(find.text("Sombre"));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
    },
  );

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pump(tester, locale: const Locale("ar"));

    expect(find.text("اللغة والمظهر"), findsOneWidget);
    expect(find.text("العربية"), findsOneWidget);
    expect(find.text("Français"), findsOneWidget);
  });

  testWidgets(
    "the AppBar back button is a real BackButton, carrying Flutter's "
    "automatic localized tooltip instead of an unlabeled custom "
    "IconButton (US-06.4)",
    (tester) async {
      await _pump(tester);

      expect(find.byType(BackButton), findsOneWidget);
      final Tooltip tooltip = tester.widget<Tooltip>(
        find
            .descendant(
              of: find.byType(BackButton),
              matching: find.byType(Tooltip),
            )
            .first,
      );
      expect(tooltip.message, isNotEmpty);
    },
  );
}
