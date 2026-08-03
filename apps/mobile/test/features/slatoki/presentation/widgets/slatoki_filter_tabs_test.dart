import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/slatoki/domain/entities/prayer_facility_filter.dart";
import "package:rahati/features/slatoki/presentation/providers/slatoki_place_providers.dart";
import "package:rahati/features/slatoki/presentation/widgets/slatoki_filter_tabs.dart";
import "package:rahati/l10n/app_localizations.dart";

Widget _wrap() {
  return ProviderScope(
    child: MaterialApp(
      theme: RahatiTheme.light,
      locale: const Locale("fr"),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(body: SlatokiFilterTabs()),
    ),
  );
}

void main() {
  testWidgets("shows the 3 localized filter tabs, 'Prière seule' selected "
      "by default", (WidgetTester tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pump();

    expect(find.text("Prière seule"), findsOneWidget);
    expect(find.text("Wudu seul"), findsOneWidget);
    expect(find.text("Prière + Wudu"), findsOneWidget);

    final TabBar tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller?.index, 0);
  });

  testWidgets("tapping a tab updates prayerFacilityFilterProvider", (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: RahatiTheme.light,
          locale: const Locale("fr"),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: SlatokiFilterTabs()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text("Wudu seul"));
    await tester.pumpAndSettle();

    expect(
      container.read(prayerFacilityFilterProvider),
      PrayerFacilityFilter.wuduOnly,
    );
  });

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: RahatiTheme.light,
          locale: const Locale("ar"),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: SlatokiFilterTabs()),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("الصلاة فقط"), findsOneWidget);
  });
}
