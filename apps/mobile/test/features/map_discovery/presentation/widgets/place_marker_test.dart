// Traces to: US-06.4 accessibility audit, finding F10 — WCAG 2.2 SC 1.4.1
// (Use of Color). Before this fix, the pin's icon was derived from
// `placeKind` (2 values), so the 4 `pinColor` categories collapsed onto
// only 2 distinct glyphs (a free vs. paid third-party place, or a plain
// vs. Slatoki-equipped RAHETI station, rendered an identical icon,
// differing only by hue). The icon is now derived from `pinColor` (4
// values) instead — this file asserts each of the 4 mappings individually
// and that no functional color changed as part of the fix.
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/core/theme/color_tokens.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/presentation/widgets/place_marker.dart";
import "package:rahati/l10n/app_localizations.dart";

Place _place(PinColor pinColor, {PlaceKind placeKind = PlaceKind.station}) =>
    Place(
      id: "p1",
      placeKind: placeKind,
      name: const LocalizedText(fr: "F", ar: "A", en: "E"),
      position: const Coordinates(latitude: 36.75, longitude: 3.06),
      pinColor: pinColor,
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
  group("PlaceMarker icon mapping (F10 — icon derived from pinColor)", () {
    testWidgets("PinColor.green (Free WC) renders Icons.wc", (tester) async {
      await tester.pumpWidget(_wrap(PlaceMarker(place: _place(PinColor.green))));

      expect(find.byIcon(Icons.wc), findsOneWidget);
    });

    testWidgets(
      "PinColor.blue (Paid WC) renders Icons.payments_outlined",
      (tester) async {
        await tester.pumpWidget(_wrap(PlaceMarker(place: _place(PinColor.blue))));

        expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
      },
    );

    testWidgets(
      "PinColor.amber (RAHETI Unit) renders Icons.verified_outlined",
      (tester) async {
        await tester.pumpWidget(
          _wrap(PlaceMarker(place: _place(PinColor.amber))),
        );

        expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      },
    );

    testWidgets(
      "PinColor.magenta (Slatoki) renders Icons.mosque",
      (tester) async {
        await tester.pumpWidget(
          _wrap(PlaceMarker(place: _place(PinColor.magenta))),
        );

        expect(find.byIcon(Icons.mosque), findsOneWidget);
      },
    );

    testWidgets(
      "the icon is chosen from pinColor, not placeKind — a station and a "
      "third-party place with the same pinColor render the same icon",
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            PlaceMarker(
              place: _place(PinColor.green, placeKind: PlaceKind.station),
            ),
          ),
        );
        expect(find.byIcon(Icons.wc), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            PlaceMarker(
              place: _place(
                PinColor.green,
                placeKind: PlaceKind.thirdPartyPlace,
              ),
            ),
          ),
        );
        expect(find.byIcon(Icons.wc), findsOneWidget);
      },
    );
  });

  group("PlaceMarker colors (unchanged by F10 — icon-only fix)", () {
    testWidgets(
      "each pinColor still fills the pin with its RahatiFunctionalColors "
      "background/foreground pair, exactly as before this fix",
      (tester) async {
        Future<Color> backgroundFor(PinColor pinColor) async {
          await tester.pumpWidget(
            _wrap(PlaceMarker(place: _place(pinColor))),
          );
          final Container container = tester.widget<Container>(
            find.descendant(
              of: find.byType(PlaceMarker),
              matching: find.byType(Container),
            ),
          );
          return (container.decoration! as BoxDecoration).color!;
        }

        final RahatiFunctionalColors colors = RahatiTheme.light
            .extension<RahatiFunctionalColors>()!;

        expect(await backgroundFor(PinColor.green), colors.success);
        expect(await backgroundFor(PinColor.blue), colors.info);
        expect(await backgroundFor(PinColor.amber), colors.rahatiUnit);
        expect(await backgroundFor(PinColor.magenta), colors.slatoki);
      },
    );
  });
}
