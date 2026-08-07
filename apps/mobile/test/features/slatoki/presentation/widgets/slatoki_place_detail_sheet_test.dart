import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/station_detail.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_detail_providers.dart";
import "package:rahati/features/map_discovery/presentation/screens/navigation_screen.dart";
import "package:rahati/features/slatoki/domain/entities/slatoki_place.dart";
import "package:rahati/features/slatoki/domain/entities/women_verification_level.dart";
import "package:rahati/features/slatoki/presentation/widgets/slatoki_place_detail_sheet.dart";
import "package:rahati/features/slatoki/presentation/widgets/slatoki_tent_status_section.dart";
import "package:rahati/l10n/app_localizations.dart";

const _center = Coordinates(latitude: 36.75, longitude: 3.06);

SlatokiPlace _place({
  WomenVerificationLevel womenVerificationLevel =
      WomenVerificationLevel.generic,
  double? averageRating,
  int reviewCount = 0,
  List<String> tags = const ["prayer", "wudu"],
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
    distanceMeters: 120,
    averageRating: averageRating,
    reviewCount: reviewCount,
    isFree: true,
    tags: tags,
  ),
  womenVerificationLevel: womenVerificationLevel,
);

Widget _wrap(SlatokiPlace place, {Locale locale = const Locale("fr")}) {
  // ProviderScope: a station-kind place embeds SlatokiTentStatusSection
  // (US-02.1.5), a ConsumerWidget — harmless to always wrap.
  return ProviderScope(
    child: MaterialApp(
      theme: RahatiTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: SlatokiPlaceDetailSheet(slatokiPlace: place)),
    ),
  );
}

void main() {
  testWidgets("shows the place name in the active locale", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_place()));
    await tester.pump();

    expect(find.text("Mosquée El Nour"), findsOneWidget);
  });

  testWidgets("verified: shows the prominent 'Femmes — section confirmée' chip "
      "directly under the header", (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        _place(
          womenVerificationLevel: WomenVerificationLevel.verifiedConfirmed,
        ),
      ),
    );
    await tester.pump();

    expect(find.text("Femmes — section confirmée"), findsOneWidget);
    expect(find.byType(Chip), findsWidgets);
  });

  testWidgets("generic: shows the neutral 'not confirmed' note", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_place()));
    await tester.pump();

    expect(find.text("Statut femmes non confirmé"), findsOneWidget);
  });

  testWidgets("shows 'no reviews yet' when averageRating is null", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_place()));
    await tester.pump();

    expect(find.text("Aucun avis"), findsOneWidget);
  });

  testWidgets("shows the rating and pluralized review count when present", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_place(averageRating: 4.6, reviewCount: 32)));
    await tester.pump();

    expect(find.text("4.6"), findsOneWidget);
    expect(find.text("(32 avis)"), findsOneWidget);
  });

  testWidgets("shows localized tag chips", (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(_place(tags: const ["prayer", "wudu"])));
    await tester.pump();

    expect(find.text("Prière"), findsOneWidget);
    expect(find.text("Wudu ✓"), findsOneWidget);
  });

  testWidgets("shows the distance", (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(_place()));
    await tester.pump();

    expect(find.text("120 m"), findsOneWidget);
  });

  testWidgets("shows an Outlined 'Itinéraire' button, per SCR-010", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_place()));
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, "Itinéraire"), findsOneWidget);
  });

  testWidgets("tapping 'Itinéraire' opens in-app navigation "
      "(AppRoutePaths.navigation) with the place's position/name — not an "
      "external maps app", (WidgetTester tester) async {
    final place = _place();
    final GoRouter router = GoRouter(
      initialLocation: "/",
      routes: <RouteBase>[
        GoRoute(
          path: "/",
          builder: (context, state) =>
              Scaffold(body: SlatokiPlaceDetailSheet(slatokiPlace: place)),
        ),
        GoRoute(
          path: AppRoutePaths.navigation,
          builder: (context, state) {
            final args = state.extra! as NavigationScreenArgs;
            return Text(
              "NAV_SCREEN:${args.destination.latitude},"
              "${args.destination.longitude}:${args.destinationLabel}",
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: RahatiTheme.light,
          locale: const Locale("fr"),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, "Itinéraire"));
    await tester.pumpAndSettle();

    expect(find.text("NAV_SCREEN:36.75,3.06:Mosquée El Nour"), findsOneWidget);
  });

  testWidgets("the close button dismisses the sheet", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: RahatiTheme.light,
          locale: const Locale("fr"),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (context) =>
                        SlatokiPlaceDetailSheet(slatokiPlace: _place()),
                  ),
                  child: const Text("open"),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(find.byType(SlatokiPlaceDetailSheet), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(SlatokiPlaceDetailSheet), findsNothing);
  });

  testWidgets("renders correctly against the dark theme", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: RahatiTheme.dark,
          locale: const Locale("fr"),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: SlatokiPlaceDetailSheet(slatokiPlace: _place())),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_place(), locale: const Locale("ar")));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("مسجد النور"), findsOneWidget);
  });

  testWidgets("RAHETI-tent place (placeKind == station): embeds "
      "SlatokiTentStatusSection instead of a generic status (US-02.1.5)", (
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
        pinColor: PinColor.amber,
        distanceMeters: 90,
        averageRating: null,
        reviewCount: 0,
        isFree: true,
        tags: const ["prayer"],
      ),
      womenVerificationLevel: WomenVerificationLevel.generic,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stationDetailProvider(
            "s1",
          ).overrideWith((ref) => Completer<StationDetail>().future),
        ],
        child: MaterialApp(
          theme: RahatiTheme.light,
          locale: const Locale("fr"),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SlatokiPlaceDetailSheet(slatokiPlace: tentPlace),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SlatokiTentStatusSection), findsOneWidget);
  });
}
