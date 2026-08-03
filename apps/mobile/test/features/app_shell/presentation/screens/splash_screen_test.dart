// Traces to: SCR-001, docs/design/wireframes/mobile-map-discovery.md#scr-001.
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/app_shell/presentation/screens/splash_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: RahatiTheme.light,
    locale: const Locale("fr"),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: child,
  );
}

void main() {
  testWidgets("shows the RAHETI wordmark and a loading indicator", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const SplashScreen()));
    await tester.pump();

    expect(find.text("RAHETI"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets("announces the loading state to assistive technology "
      "(wireframe accessibility requirement)", (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const SplashScreen()));
    await tester.pump();

    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel("RAHETI, chargement en cours"),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets("renders correctly against the dark theme", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RahatiTheme.dark,
        locale: const Locale("fr"),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const SplashScreen(),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("RAHETI"), findsOneWidget);
  });
}
