// Traces to: US-01.1.4 (FR-MAP-04).
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/presentation/widgets/map_search_bar.dart";
import "package:rahati/l10n/app_localizations.dart";

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: RahatiTheme.light,
    locale: const Locale("fr"),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets("shows the localized hint text", (tester) async {
    await tester.pumpWidget(_wrap(MapSearchBar(onQueryChanged: (_) {})));
    expect(find.text("Rechercher un lieu…"), findsOneWidget);
  });

  testWidgets(
    "does not call onQueryChanged while the debounce window is still open",
    (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _wrap(
          MapSearchBar(
            onQueryChanged: calls.add,
            debounceDuration: const Duration(milliseconds: 300),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), "wc");
      await tester.pump(const Duration(milliseconds: 100));

      expect(calls, isEmpty);
    },
  );

  testWidgets(
    "calls onQueryChanged once with the settled value after the debounce "
    "window elapses",
    (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _wrap(
          MapSearchBar(
            onQueryChanged: calls.add,
            debounceDuration: const Duration(milliseconds: 300),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), "w");
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), "wc");
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), "wc gratuit");
      await tester.pump(const Duration(milliseconds: 350));

      expect(calls, ["wc gratuit"]);
    },
  );

  testWidgets("the clear button resets the field and calls onQueryChanged("
      "'') immediately", (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(_wrap(MapSearchBar(onQueryChanged: calls.add)));

    await tester.enterText(find.byType(TextField), "wc");
    await tester.pump(const Duration(milliseconds: 350));
    expect(calls, ["wc"]);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(find.text("wc"), findsNothing);
    expect(calls.last, "");
  });

  testWidgets(
    "exposes a single, unambiguous accessible name via hintText — no "
    "explicit Semantics wrapper needed (US-06.4 finding F17, verified as "
    "a false positive: SearchBar's own TextField/InputDecorator "
    "composition already surfaces hintText as the field's persistent "
    "semantics label; an added external Semantics(label:) wrapper was "
    "tried and produced a genuine duplicate node, so it was reverted)",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(MapSearchBar(onQueryChanged: (_) {})));

      expect(find.bySemanticsLabel("Rechercher un lieu…"), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    "the accessible name persists once text is entered — a single node, "
    "not tied to the hint's visual disappearance",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(MapSearchBar(onQueryChanged: (_) {})));

      await tester.enterText(find.byType(TextField), "wc");
      await tester.pump();

      expect(find.bySemanticsLabel("Rechercher un lieu…"), findsOneWidget);
      handle.dispose();
    },
  );
}
