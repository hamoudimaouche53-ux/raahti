import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/route.dart";
import "package:rahati/features/map_discovery/presentation/widgets/route_information_card.dart";
import "package:rahati/l10n/app_localizations.dart";

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: RahatiTheme.light,
    locale: const Locale("en"),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

NavigationRoute _route({
  required double distanceMeters,
  required double durationSeconds,
}) => NavigationRoute(
  points: const <Coordinates>[],
  distanceMeters: distanceMeters,
  durationSeconds: durationSeconds,
);

void main() {
  testWidgets("shows distance remaining formatted in km above 1000m", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        RouteInformationCard(
          route: _route(distanceMeters: 1234, durationSeconds: 600),
          isRefreshing: false,
        ),
      ),
    );

    expect(find.textContaining("1.2 km"), findsOneWidget);
  });

  testWidgets("shows distance remaining formatted in meters below 1000m", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        RouteInformationCard(
          route: _route(distanceMeters: 450, durationSeconds: 300),
          isRefreshing: false,
        ),
      ),
    );

    expect(find.textContaining("450 m"), findsOneWidget);
  });

  testWidgets("shows walking time computed from durationSeconds", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        RouteInformationCard(
          route: _route(distanceMeters: 450, durationSeconds: 600),
          isRefreshing: false,
        ),
      ),
    );

    // 600s = 10 min.
    expect(find.textContaining("10 min"), findsOneWidget);
  });

  testWidgets("shows a refreshing spinner only when isRefreshing is true", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        RouteInformationCard(
          route: _route(distanceMeters: 450, durationSeconds: 300),
          isRefreshing: true,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        RouteInformationCard(
          route: _route(distanceMeters: 450, durationSeconds: 300),
          isRefreshing: false,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets("exposes distance/time/arrival as a single live-region "
      "semantics label", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        RouteInformationCard(
          route: _route(distanceMeters: 450, durationSeconds: 300),
          isRefreshing: false,
        ),
      ),
    );

    final SemanticsNode node = tester.getSemantics(
      find.byType(RouteInformationCard),
    );
    expect(node.label, contains("450 m"));
    expect(node.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });
}
