// Traces to: Component Library §9.3, US-01.2.2 (FR-PLC-02).
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/cabin.dart";
import "package:rahati/features/map_discovery/presentation/widgets/cabin_status_indicator.dart";
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
  testWidgets("shows 'Libre' with an accessible label for free", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(const CabinStatusIndicator(status: CabinOccupancyStatus.free)),
    );

    expect(find.text("Libre"), findsOneWidget);
    expect(find.bySemanticsLabel("Libre"), findsOneWidget);
    handle.dispose();
  });

  testWidgets("shows 'Occupé' for occupied", (tester) async {
    await tester.pumpWidget(
      _wrap(const CabinStatusIndicator(status: CabinOccupancyStatus.occupied)),
    );
    expect(find.text("Occupé"), findsOneWidget);
  });

  testWidgets("shows 'Hors service' for out of service", (tester) async {
    await tester.pumpWidget(
      _wrap(
        const CabinStatusIndicator(status: CabinOccupancyStatus.outOfService),
      ),
    );
    expect(find.text("Hors service"), findsOneWidget);
  });

  testWidgets("uses distinct colors for each status (never color-only, but "
      "still a real visual difference)", (tester) async {
    final Set<Color> colors = {};
    for (final status in CabinOccupancyStatus.values) {
      await tester.pumpWidget(_wrap(CabinStatusIndicator(status: status)));
      final Container dot = tester.widget(find.byType(Container));
      colors.add((dot.decoration as BoxDecoration).color!);
    }
    expect(colors, hasLength(CabinOccupancyStatus.values.length));
  });
}
