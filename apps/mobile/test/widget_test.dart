// Foundation smoke test — verifies the app boots end-to-end through
// Riverpod → GoRouter → MaterialApp.router → SplashScreen without throwing,
// with the default (system) theme/locale resolution.
//
// Traces to: ADR-0018 (Flutter project foundation), SCR-001
// (docs/design/screen-inventory.md).
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/app.dart";
import "package:rahati/l10n/app_localizations.dart";

void main() {
  testWidgets("RahatiApp boots and shows the splash screen", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RahatiApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text("RAHETI"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets("App title resolves via AppLocalizations", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RahatiApp()));
    await tester.pump();

    // `find.byType(MaterialApp)` gives an element *above* where
    // MaterialApp's own Localizations widget is installed; the Scaffold
    // rendered by SplashScreen is below it, so its context can see it.
    final BuildContext context = tester.element(find.byType(Scaffold));
    expect(AppLocalizations.of(context).appName, "RAHETI");
  });
}
