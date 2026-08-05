// Traces to: US-01.1.2, docs/design/foundations.md §1.3 (usage rule —
// generic UI chrome uses M3 baseline roles, not RAH-DOC-002 functional
// colors).
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/core/theme/color_tokens.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/presentation/clustering/map_marker_item.dart";
import "package:rahati/features/map_discovery/presentation/widgets/cluster_marker.dart";
import "package:rahati/l10n/app_localizations.dart";

Place _place(String id) => Place(
  id: id,
  placeKind: PlaceKind.station,
  name: const LocalizedText(fr: "F", ar: "A", en: "E"),
  position: const Coordinates(latitude: 36.75, longitude: 3.06),
  pinColor: PinColor.blue,
  distanceMeters: 0,
  averageRating: null,
  reviewCount: 0,
  isFree: true,
  tags: const <String>[],
);

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
  testWidgets("shows the member count and announces it via semantics", (
    tester,
  ) async {
    final cluster = PlaceClusterItem(
      position: const Coordinates(latitude: 36.75, longitude: 3.06),
      places: [_place("1"), _place("2"), _place("3")],
    );

    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(ClusterMarker(cluster: cluster)));

    expect(find.text("3"), findsOneWidget);
    expect(find.bySemanticsLabel("3 lieux à proximité"), findsOneWidget);
    handle.dispose();
  });

  testWidgets("invokes onTap when tapped", (tester) async {
    final cluster = PlaceClusterItem(
      position: const Coordinates(latitude: 36.75, longitude: 3.06),
      places: [_place("1"), _place("2")],
    );
    bool tapped = false;

    await tester.pumpWidget(
      _wrap(ClusterMarker(cluster: cluster, onTap: () => tapped = true)),
    );
    await tester.tap(find.byType(ClusterMarker));

    expect(tapped, isTrue);
  });

  testWidgets("uses the M3 secondaryContainer role, not a functional color", (
    tester,
  ) async {
    final cluster = PlaceClusterItem(
      position: const Coordinates(latitude: 36.75, longitude: 3.06),
      places: [_place("1"), _place("2")],
    );

    await tester.pumpWidget(_wrap(ClusterMarker(cluster: cluster)));

    final Container container = tester.widget<Container>(
      find.descendant(
        of: find.byType(ClusterMarker),
        matching: find.byType(Container),
      ),
    );
    final BoxDecoration decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, RahatiColorTokens.light.secondaryContainer);
  });

  testWidgets("the tap target is 48x48dp even for a small cluster whose visual "
      "diameter is well under 48dp (US-06.4)", (tester) async {
    final cluster = PlaceClusterItem(
      position: const Coordinates(latitude: 36.75, longitude: 3.06),
      places: [_place("1"), _place("2")],
    );

    await tester.pumpWidget(_wrap(ClusterMarker(cluster: cluster)));

    expect(tester.getSize(find.byType(ClusterMarker)), const Size(48, 48));
  });
}
