// Traces to: US-01.1.6 (FR-MAP-06).
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/presentation/widgets/recenter_fab.dart";
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
  testWidgets("shows a filled GPS icon and the locked tooltip when locked", (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(RecenterFab(isLocked: true, onPressed: () {})),
    );

    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    expect(find.byIcon(Icons.gps_not_fixed), findsNothing);
    expect(
      find.bySemanticsLabel("Suivi de position actif — appuyer pour recentrer"),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets(
    "shows an outline GPS icon and the unlocked tooltip when unlocked",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(RecenterFab(isLocked: false, onPressed: () {})),
      );

      expect(find.byIcon(Icons.gps_not_fixed), findsOneWidget);
      expect(find.byIcon(Icons.gps_fixed), findsNothing);
      expect(
        find.bySemanticsLabel("Recentrer sur ma position"),
        findsOneWidget,
      );
      handle.dispose();
    },
  );

  testWidgets("uses distinct M3 color roles for locked vs. unlocked "
      "(not color-only, but a real visual difference)", (tester) async {
    await tester.pumpWidget(
      _wrap(RecenterFab(isLocked: true, onPressed: () {})),
    );
    final FloatingActionButton lockedFab = tester.widget(
      find.byType(FloatingActionButton),
    );

    await tester.pumpWidget(
      _wrap(RecenterFab(isLocked: false, onPressed: () {})),
    );
    final FloatingActionButton unlockedFab = tester.widget(
      find.byType(FloatingActionButton),
    );

    expect(lockedFab.backgroundColor, isNot(unlockedFab.backgroundColor));
  });

  testWidgets("calls onPressed when tapped", (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(RecenterFab(isLocked: true, onPressed: () => tapped = true)),
    );

    await tester.tap(find.byType(RecenterFab));

    expect(tapped, isTrue);
  });
}
