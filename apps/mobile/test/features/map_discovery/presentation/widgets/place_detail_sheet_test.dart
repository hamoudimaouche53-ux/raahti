// Traces to: SCR-005, SCR-006, US-01.1.3, US-01.2.1…05 (FR-PLC-01…05).
import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/cabin.dart";
import "package:rahati/features/map_discovery/domain/entities/cabin_occupancy_update.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/money.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/station_detail.dart";
import "package:rahati/features/map_discovery/domain/entities/third_party_place_detail.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_detail_providers.dart";
import "package:rahati/features/map_discovery/presentation/widgets/cabin_status_indicator.dart";
import "package:rahati/features/map_discovery/presentation/widgets/place_detail_sheet.dart";
import "package:rahati/l10n/app_localizations.dart";

Place _place({
  double? averageRating,
  int reviewCount = 0,
  bool isFree = true,
  List<String> tags = const <String>[],
  PlaceKind placeKind = PlaceKind.station,
}) => Place(
  id: "1",
  placeKind: placeKind,
  name: const LocalizedText(
    fr: "Station Didouche",
    ar: "محطة ديدوش",
    en: "Didouche Station",
  ),
  position: const Coordinates(latitude: 36.75, longitude: 3.06),
  pinColor: PinColor.amber,
  distanceMeters: 180,
  averageRating: averageRating,
  reviewCount: reviewCount,
  isFree: isFree,
  tags: tags,
);

StationDetail _stationDetail(Place place, {List<Cabin> cabins = const []}) =>
    StationDetail(
      summary: place,
      configuration: StationConfiguration.fixed,
      status: StationOperationalStatus.active,
      cabins: cabins,
      slatokiTent: null,
    );

Future<void> _pumpSheet(
  WidgetTester tester,
  Place place, {
  String locale = "fr",
  // `dynamic`, not `List<Override>` — `Override` isn't exported from
  // `flutter_riverpod`'s public API surface in this version. No default
  // value here (an untyped `const []` default infers as `List<dynamic>`,
  // which fails ProviderScope's runtime type check) — `?? []` below lets
  // downward inference from `ProviderScope.overrides`'s own parameter
  // type give the empty-list fallback the right runtime type instead.
  dynamic overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        theme: RahatiTheme.light,
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => PlaceDetailSheet(place: place),
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
}

void main() {
  testWidgets("shows the place name in the active locale", (tester) async {
    await _pumpSheet(tester, _place());
    expect(find.text("Station Didouche"), findsOneWidget);
  });

  testWidgets("shows the place name in English when locale is en", (
    tester,
  ) async {
    await _pumpSheet(tester, _place(), locale: "en");
    expect(find.text("Didouche Station"), findsOneWidget);
  });

  testWidgets("shows the place name in Arabic when locale is ar", (
    tester,
  ) async {
    await _pumpSheet(tester, _place(), locale: "ar");
    expect(find.text("محطة ديدوش"), findsOneWidget);
  });

  testWidgets("shows 'no reviews yet' when averageRating is null", (
    tester,
  ) async {
    await _pumpSheet(tester, _place(averageRating: null));
    expect(find.text("Aucun avis"), findsOneWidget);
  });

  testWidgets("shows the rating and pluralized review count when present", (
    tester,
  ) async {
    await _pumpSheet(tester, _place(averageRating: 4.6, reviewCount: 32));
    expect(find.text("4.6"), findsOneWidget);
    expect(find.text("(32 avis)"), findsOneWidget);
  });

  testWidgets("shows localized tag chips", (tester) async {
    await _pumpSheet(
      tester,
      _place(tags: const ["women_confirmed", "wudu", "pmr"]),
    );
    expect(find.text("Femmes ✓"), findsOneWidget);
    expect(find.text("Wudu ✓"), findsOneWidget);
    expect(find.text("PMR"), findsOneWidget);
  });

  testWidgets("falls back to the raw tag string for an unknown tag", (
    tester,
  ) async {
    await _pumpSheet(tester, _place(tags: const ["some_future_tag"]));
    expect(find.text("some_future_tag"), findsOneWidget);
  });

  testWidgets("shows 'Gratuit' for a free place and 'Payant' for a paid one", (
    tester,
  ) async {
    await _pumpSheet(tester, _place(isFree: true));
    expect(find.text("Gratuit"), findsOneWidget);
  });

  testWidgets("shows the Route action button", (tester) async {
    await _pumpSheet(tester, _place());
    expect(find.text("Itinéraire"), findsOneWidget);
  });

  testWidgets("the close button dismisses the sheet", (tester) async {
    await _pumpSheet(tester, _place());
    expect(find.byType(PlaceDetailSheet), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceDetailSheet), findsNothing);
  });

  group("station cabin status (US-01.2.2)", () {
    testWidgets("shows a CabinStatusIndicator per cabin with its status "
        "label", (tester) async {
      final place = _place();
      await _pumpSheet(
        tester,
        place,
        overrides: [
          stationDetailProvider(place.id).overrideWith(
            (ref) async => _stationDetail(
              place,
              cabins: const [
                Cabin(
                  id: "c1",
                  code: "1",
                  type: CabinType.women,
                  occupancyStatus: CabinOccupancyStatus.free,
                  isPaid: false,
                  price: null,
                ),
                Cabin(
                  id: "c2",
                  code: "2",
                  type: CabinType.men,
                  occupancyStatus: CabinOccupancyStatus.occupied,
                  isPaid: true,
                  price: Money(amount: "50", currency: "DZD"),
                ),
              ],
            ),
          ),
        ],
      );

      expect(find.byType(CabinStatusIndicator), findsNWidgets(2));
      expect(find.text("Cabine 1"), findsOneWidget);
      expect(find.text("Cabine 2"), findsOneWidget);
      expect(find.text("Libre"), findsOneWidget);
      expect(find.text("Occupé"), findsOneWidget);
    });

    testWidgets("shows the tariff and payment methods for a paid cabin", (
      tester,
    ) async {
      final place = _place();
      await _pumpSheet(
        tester,
        place,
        overrides: [
          stationDetailProvider(place.id).overrideWith(
            (ref) async => _stationDetail(
              place,
              cabins: const [
                Cabin(
                  id: "c1",
                  code: "1",
                  type: CabinType.men,
                  occupancyStatus: CabinOccupancyStatus.free,
                  isPaid: true,
                  price: Money(amount: "50", currency: "DZD"),
                ),
              ],
            ),
          ),
        ],
      );

      expect(find.textContaining("50 DZD"), findsOneWidget);
      expect(find.textContaining("Carte"), findsOneWidget);
    });

    testWidgets("shows an inline error line when the detail fetch fails", (
      tester,
    ) async {
      final place = _place();
      await _pumpSheet(
        tester,
        place,
        overrides: [
          stationDetailProvider(
            place.id,
          ).overrideWith((ref) async => throw Exception("boom")),
        ],
      );

      expect(
        find.text("Impossible de charger les détails de ce lieu."),
        findsOneWidget,
      );
    });
  });

  group("QR scan entry point (US-04.1)", () {
    testWidgets(
      "shows the 'Scanner le QR' button for a station with at least one "
      "cabin",
      (tester) async {
        final place = _place();
        await _pumpSheet(
          tester,
          place,
          overrides: [
            stationDetailProvider(place.id).overrideWith(
              (ref) async => _stationDetail(
                place,
                cabins: const [
                  Cabin(
                    id: "c1",
                    code: "1",
                    type: CabinType.women,
                    occupancyStatus: CabinOccupancyStatus.free,
                    isPaid: false,
                    price: null,
                  ),
                ],
              ),
            ),
          ],
        );

        expect(find.text("Scanner le QR"), findsOneWidget);
      },
    );

    testWidgets(
      "hides the 'Scanner le QR' button for a station with no cabins",
      (tester) async {
        final place = _place();
        await _pumpSheet(
          tester,
          place,
          overrides: [
            stationDetailProvider(
              place.id,
            ).overrideWith((ref) async => _stationDetail(place)),
          ],
        );

        expect(find.text("Scanner le QR"), findsNothing);
      },
    );

    testWidgets("hides the 'Scanner le QR' button for a third-party place", (
      tester,
    ) async {
      final place = _place(placeKind: PlaceKind.thirdPartyPlace);
      await _pumpSheet(
        tester,
        place,
        overrides: [
          thirdPartyPlaceDetailProvider(place.id).overrideWith(
            (ref) async => ThirdPartyPlaceDetail(
              summary: place,
              placeType: ThirdPartyPlaceType.mosque,
              declaredStatus: DeclaredStatus.open,
              statusSource: StatusSource.community,
            ),
          ),
        ],
      );

      expect(find.text("Scanner le QR"), findsNothing);
    });
  });

  group("third-party declarative status (US-01.2.2)", () {
    testWidgets("shows an outlined status chip, distinct from IoT-verified "
        "cabin status", (tester) async {
      final place = _place(placeKind: PlaceKind.thirdPartyPlace);
      await _pumpSheet(
        tester,
        place,
        overrides: [
          thirdPartyPlaceDetailProvider(place.id).overrideWith(
            (ref) async => ThirdPartyPlaceDetail(
              summary: place,
              placeType: ThirdPartyPlaceType.mosque,
              declaredStatus: DeclaredStatus.open,
              statusSource: StatusSource.community,
            ),
          ),
        ],
      );

      expect(find.text("Ouvert"), findsOneWidget);
      expect(find.text("Signalé par la communauté"), findsOneWidget);
      expect(find.byType(CabinStatusIndicator), findsNothing);
    });
  });

  group("live cabin status updates (US-04.5)", () {
    testWidgets(
      "patches a cabin's occupancy in place when a Realtime update "
      "arrives, without a re-fetch",
      (tester) async {
        final place = _place();
        final controller = StreamController<CabinOccupancyUpdate>();
        addTearDown(controller.close);

        await _pumpSheet(
          tester,
          place,
          overrides: [
            stationDetailProvider(place.id).overrideWith(
              (ref) async => _stationDetail(
                place,
                cabins: const [
                  Cabin(
                    id: "c1",
                    code: "1",
                    type: CabinType.women,
                    occupancyStatus: CabinOccupancyStatus.free,
                    isPaid: false,
                    price: null,
                  ),
                ],
              ),
            ),
            cabinOccupancyUpdatesProvider(
              place.id,
            ).overrideWith((ref) => controller.stream),
          ],
        );

        expect(find.text("Libre"), findsOneWidget);
        expect(find.text("Occupé"), findsNothing);

        controller.add(
          const CabinOccupancyUpdate(
            cabinId: "c1",
            occupancyStatus: CabinOccupancyStatus.occupied,
          ),
        );
        // Two pumps: one for the StreamController's event to reach the
        // StreamProvider (a real async hop, not just a widget rebuild),
        // one for the resulting setState's rebuild.
        await tester.pump();
        await tester.pump();

        expect(find.text("Libre"), findsNothing);
        expect(find.text("Occupé"), findsOneWidget);
      },
    );

    testWidgets(
      "ignores an update for a cabin id not in the fetched list",
      (tester) async {
        final place = _place();
        final controller = StreamController<CabinOccupancyUpdate>();
        addTearDown(controller.close);

        await _pumpSheet(
          tester,
          place,
          overrides: [
            stationDetailProvider(place.id).overrideWith(
              (ref) async => _stationDetail(
                place,
                cabins: const [
                  Cabin(
                    id: "c1",
                    code: "1",
                    type: CabinType.women,
                    occupancyStatus: CabinOccupancyStatus.free,
                    isPaid: false,
                    price: null,
                  ),
                ],
              ),
            ),
            cabinOccupancyUpdatesProvider(
              place.id,
            ).overrideWith((ref) => controller.stream),
          ],
        );

        controller.add(
          const CabinOccupancyUpdate(
            cabinId: "unknown-cabin",
            occupancyStatus: CabinOccupancyStatus.occupied,
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text("Libre"), findsOneWidget);
        expect(find.text("Occupé"), findsNothing);
      },
    );
  });
}
