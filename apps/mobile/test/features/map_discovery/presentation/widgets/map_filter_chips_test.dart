// Traces to: US-01.1.5 (FR-MAP-05).
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/place_filter.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_filter_provider.dart";
import "package:rahati/features/map_discovery/presentation/widgets/map_filter_chips.dart";
import "package:rahati/l10n/app_localizations.dart";

Widget _wrap() {
  return ProviderScope(
    child: MaterialApp(
      theme: RahatiTheme.light,
      locale: const Locale("fr"),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: MapFilterChips()),
    ),
  );
}

FilterChip _chip(WidgetTester tester, String label) =>
    tester.widget<FilterChip>(
      find.ancestor(of: find.text(label), matching: find.byType(FilterChip)),
    );

void main() {
  testWidgets("shows the FR-MAP-05 category chips and 'Tout' selected by "
      "default", (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text("Tout"), findsOneWidget);
    expect(find.text("Gratuit"), findsOneWidget);
    expect(find.text("Payant"), findsOneWidget);
    expect(find.text("RAHETI"), findsOneWidget);
    expect(find.text("Slatoki"), findsOneWidget);
    expect(_chip(tester, "Tout").selected, isTrue);
  });

  testWidgets("selecting a category chip deselects 'Tout' in the state", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MapFilterChips)),
    );

    await tester.tap(find.text("Gratuit"));
    await tester.pump();

    expect(container.read(placeFilterProvider).categories, {
      PlaceCategory.free,
    });
    expect(_chip(tester, "Tout").selected, isFalse);
    expect(_chip(tester, "Gratuit").selected, isTrue);
  });

  testWidgets("multiple category chips can be selected together", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());

    await tester.tap(find.text("Gratuit"));
    await tester.pump();
    await tester.tap(find.text("Slatoki"));
    await tester.pump();

    expect(_chip(tester, "Gratuit").selected, isTrue);
    expect(_chip(tester, "Slatoki").selected, isTrue);
  });

  testWidgets("tapping 'Tout' clears every selection", (tester) async {
    await tester.pumpWidget(_wrap());

    await tester.tap(find.text("Gratuit"));
    await tester.pump();
    await tester.tap(find.text("Tout"));
    await tester.pump();

    expect(_chip(tester, "Tout").selected, isTrue);
    expect(_chip(tester, "Gratuit").selected, isFalse);
  });

  testWidgets("distance chips are single-select and toggle off on a second "
      "tap", (tester) async {
    await tester.pumpWidget(_wrap());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MapFilterChips)),
    );

    await tester.ensureVisible(find.text("< 1 km"));
    await tester.tap(find.text("< 1 km"));
    await tester.pump();
    expect(
      container.read(placeFilterProvider).distance,
      DistanceFilter.under1km,
    );

    await tester.ensureVisible(find.text("< 5 km"));
    await tester.tap(find.text("< 5 km"));
    await tester.pump();
    expect(
      container.read(placeFilterProvider).distance,
      DistanceFilter.under5km,
    );
    expect(_chip(tester, "< 1 km").selected, isFalse);
    expect(_chip(tester, "< 5 km").selected, isTrue);

    await tester.ensureVisible(find.text("< 5 km"));
    await tester.tap(find.text("< 5 km"));
    await tester.pump();
    expect(container.read(placeFilterProvider).distance, DistanceFilter.any);
  });
}
