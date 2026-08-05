import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/profile/presentation/screens/notification_settings_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

Future<void> _pump(
  WidgetTester tester, {
  Locale locale = const Locale("fr"),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: RahatiTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const NotificationSettingsScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    "shows the three toggle rows, favorites/payment on and news off by "
    "default",
    (tester) async {
      await _pump(tester);

      expect(find.text("Disponibilité des favoris"), findsOneWidget);
      expect(find.text("Alertes de paiement"), findsOneWidget);
      expect(find.text("Actualités RAHETI"), findsOneWidget);

      final List<SwitchListTile> tiles = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(tiles[0].value, isTrue);
      expect(tiles[1].value, isTrue);
      expect(tiles[2].value, isFalse);
    },
  );

  testWidgets("toggling a row flips its value", (tester) async {
    await _pump(tester);

    await tester.tap(find.text("Actualités RAHETI"));
    await tester.pumpAndSettle();

    final SwitchListTile newsTile = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .last;
    expect(newsTile.value, isTrue);
  });

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pump(tester, locale: const Locale("ar"));

    expect(find.text("إعدادات الإشعارات"), findsOneWidget);
  });

  testWidgets("the AppBar back button is a real BackButton, carrying Flutter's "
      "automatic localized tooltip instead of an unlabeled custom "
      "IconButton (US-06.4)", (tester) async {
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
  });
}
