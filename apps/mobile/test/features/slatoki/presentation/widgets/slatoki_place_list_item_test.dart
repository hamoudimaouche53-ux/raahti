import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/slatoki/domain/entities/slatoki_place.dart";
import "package:rahati/features/slatoki/domain/entities/women_verification_level.dart";
import "package:rahati/features/slatoki/presentation/widgets/slatoki_place_list_item.dart";
import "package:rahati/features/slatoki/presentation/widgets/slatoki_tent_status_section.dart";
import "package:rahati/l10n/app_localizations.dart";

const _center = Coordinates(latitude: 36.75, longitude: 3.06);

Widget _wrap(
  SlatokiPlace place, {
  Locale locale = const Locale("fr"),
  VoidCallback? onTap,
}) {
  // ProviderScope: station-kind places render SlatokiTentStatusSection
  // (US-02.1.5), a ConsumerWidget — harmless to always wrap.
  return ProviderScope(
    child: MaterialApp(
      theme: RahatiTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SlatokiPlaceListItem(slatokiPlace: place, onTap: onTap),
      ),
    ),
  );
}

SlatokiPlace _place({
  required double distanceMeters,
  WomenVerificationLevel womenVerificationLevel =
      WomenVerificationLevel.generic,
}) => SlatokiPlace(
  place: Place(
    id: "1",
    placeKind: PlaceKind.thirdPartyPlace,
    name: LocalizedText(
      fr: "Mosquée El Nour",
      ar: "مسجد النور",
      en: "El Nour Mosque",
    ),
    position: _center,
    pinColor: PinColor.magenta,
    distanceMeters: distanceMeters,
    averageRating: null,
    reviewCount: 0,
    isFree: true,
    tags: const ["prayer", "wudu"],
  ),
  womenVerificationLevel: womenVerificationLevel,
);

void main() {
  testWidgets("shows the place name in the active locale", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_place(distanceMeters: 120)));
    await tester.pump();

    expect(find.text("Mosquée El Nour"), findsOneWidget);
  });

  testWidgets("formats distance under 1km in meters", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_place(distanceMeters: 120)));
    await tester.pump();

    expect(find.text("120 m"), findsOneWidget);
  });

  testWidgets("formats distance at/over 1km in kilometers", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_place(distanceMeters: 1500)));
    await tester.pump();

    expect(find.text("1.5 km"), findsOneWidget);
  });

  testWidgets("shows the Arabic name under the Arabic locale", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_place(distanceMeters: 120), locale: const Locale("ar")),
    );
    await tester.pump();

    expect(find.text("مسجد النور"), findsOneWidget);
  });

  testWidgets(
    "verified: shows the 'Femmes ✓' badge (US-02.1.4, reusing tagWomenConfirmed)",
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          _place(
            distanceMeters: 120,
            womenVerificationLevel: WomenVerificationLevel.verifiedConfirmed,
          ),
        ),
      );
      await tester.pump();

      expect(find.text("Femmes ✓"), findsOneWidget);
    },
  );

  testWidgets("generic: does not show the 'Femmes ✓' badge", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_place(distanceMeters: 120)));
    await tester.pump();

    expect(find.text("Femmes ✓"), findsNothing);
  });

  testWidgets("tapping the item invokes onTap", (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      _wrap(_place(distanceMeters: 120), onTap: () => tapped = true),
    );
    await tester.pump();

    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });

  testWidgets("RAHETI-tent place (placeKind == station): renders "
      "SlatokiTentStatusSection instead (US-02.1.5)", (
    WidgetTester tester,
  ) async {
    final tentPlace = SlatokiPlace(
      place: Place(
        id: "s1",
        placeKind: PlaceKind.station,
        name: const LocalizedText(
          fr: "Tente RAHETI Didouche",
          ar: "خيمة",
          en: "RAHETI Tent",
        ),
        position: _center,
        pinColor: PinColor.magenta,
        distanceMeters: 90,
        averageRating: null,
        reviewCount: 0,
        isFree: true,
        tags: const ["prayer"],
      ),
      womenVerificationLevel: WomenVerificationLevel.generic,
    );

    await tester.pumpWidget(_wrap(tentPlace));
    await tester.pump();

    expect(find.byType(SlatokiTentStatusSection), findsOneWidget);
    expect(find.text("Tente RAHETI Didouche"), findsOneWidget);
  });
}
