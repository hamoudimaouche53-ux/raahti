// Traces to: ADR-0024. Zero business logic to test — only that the
// placeholder renders, is themed, and is announced correctly.
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/emergency/presentation/screens/emergency_placeholder_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

Widget _wrap(
  Widget child, {
  ThemeData? theme,
  Locale locale = const Locale("fr"),
}) {
  return MaterialApp(
    theme: theme ?? RahatiTheme.light,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: child,
  );
}

void main() {
  testWidgets("shows the localized title and 'coming in V1.1' body", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const EmergencyPlaceholderScreen()));
    await tester.pump();

    expect(find.text("Mode Urgence"), findsOneWidget);
    expect(find.text("Disponible dans la version V1.1."), findsOneWidget);
  });

  testWidgets("announces the placeholder state to assistive technology", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const EmergencyPlaceholderScreen()));
    await tester.pump();

    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel("Mode Urgence. Disponible dans la version V1.1."),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets("renders correctly against the dark theme", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const EmergencyPlaceholderScreen(), theme: RahatiTheme.dark),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("Mode Urgence"), findsOneWidget);
  });

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const EmergencyPlaceholderScreen(), locale: const Locale("ar")),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.text("وضع الطوارئ"))),
      TextDirection.rtl,
    );
  });
}
