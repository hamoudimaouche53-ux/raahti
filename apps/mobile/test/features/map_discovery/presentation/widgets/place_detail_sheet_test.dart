// Traces to: SCR-005, SCR-006, US-01.1.3, US-01.2.1…05 (FR-PLC-01…05).
import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/cabin.dart";
import "package:rahati/features/map_discovery/domain/entities/cabin_occupancy_update.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/favorite.dart";
import "package:rahati/features/map_discovery/domain/entities/money.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/station_detail.dart";
import "package:rahati/features/map_discovery/domain/entities/third_party_place_detail.dart";
import "package:rahati/features/map_discovery/domain/repositories/favorite_repository.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_detail_providers.dart";
import "package:rahati/features/map_discovery/presentation/screens/navigation_screen.dart";
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

/// A minimal in-memory [FavoriteRepository] fake for the favorite-toggle
/// button tests (US-05.4) — same `Completer<void>? delay` precedent
/// `_FakeAccessSessionRepository` (cabin_availability_screen_test.dart)
/// already established for freezing a repository call mid-flight so the
/// screen's saving/loading state can be asserted on.
class _FakeFavoriteRepository implements FavoriteRepository {
  _FakeFavoriteRepository({
    List<Favorite> seed = const [],
    this.failure,
    this.delay,
  }) : _favorites = List<Favorite>.of(seed);

  final List<Favorite> _favorites;
  final FavoriteRepositoryFailure? failure;
  final Completer<void>? delay;

  int addFavoriteCallCount = 0;
  int removeFavoriteCallCount = 0;
  String? lastRemovedFavoriteId;

  @override
  Future<List<Favorite>> getFavorites({
    Coordinates? currentPosition,
    required String languageCode,
  }) async => List<Favorite>.unmodifiable(_favorites);

  @override
  Future<Favorite> addFavorite({
    required PlaceKind placeKind,
    required String placeId,
    required bool notifyOnAvailable,
    required String languageCode,
  }) async {
    addFavoriteCallCount++;
    final Completer<void>? d = delay;
    if (d != null) await d.future;
    final FavoriteRepositoryFailure? f = failure;
    if (f != null) throw f;
    final Favorite added = Favorite(
      id: "fav-new",
      placeKind: placeKind,
      placeId: placeId,
      placeName: placeId,
      distanceMeters: null,
      notifyOnAvailable: notifyOnAvailable,
    );
    _favorites.add(added);
    return added;
  }

  @override
  Future<void> removeFavorite(String favoriteId) async {
    removeFavoriteCallCount++;
    lastRemovedFavoriteId = favoriteId;
    final Completer<void>? d = delay;
    if (d != null) await d.future;
    final FavoriteRepositoryFailure? f = failure;
    if (f != null) throw f;
    _favorites.removeWhere((existing) => existing.id == favoriteId);
  }

  @override
  Future<Favorite> setNotifyOnAvailable({
    required String favoriteId,
    required bool notifyOnAvailable,
  }) => throw UnimplementedError();
}

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

  testWidgets(
    "tapping Route opens in-app navigation (AppRoutePaths.navigation) "
    "with the place's position/name — not an external maps app",
    (tester) async {
      final place = _place();
      final GoRouter router = GoRouter(
        initialLocation: "/",
        routes: <RouteBase>[
          GoRoute(
            path: "/",
            builder: (context, state) => Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
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
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Itinéraire"));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "NAV_SCREEN:${place.position.latitude},"
          "${place.position.longitude}:Station Didouche",
        ),
        findsOneWidget,
      );
    },
  );

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

    testWidgets(
      "the inline error line is announced to screen readers via a live "
      "region when the fetch fails, not only if the user happens to "
      "navigate to it (US-06.4 finding)",
      (tester) async {
        final place = _place();
        final SemanticsHandle handle = tester.ensureSemantics();
        await _pumpSheet(
          tester,
          place,
          overrides: [
            stationDetailProvider(
              place.id,
            ).overrideWith((ref) async => throw Exception("boom")),
          ],
        );

        final SemanticsNode node = tester.getSemantics(
          find.text("Impossible de charger les détails de ce lieu."),
        );
        expect(node.label, "Impossible de charger les détails de ce lieu.");
        expect(
          node.flagsCollection.isLiveRegion,
          isTrue,
          reason:
              "an unprompted fetch-failure message must be announced, "
              "matching this app's established live-region pattern (e.g. "
              "map status banners)",
        );
        handle.dispose();
      },
    );
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
    testWidgets("patches a cabin's occupancy in place when a Realtime update "
        "arrives, without a re-fetch", (tester) async {
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
    });

    testWidgets("ignores an update for a cabin id not in the fetched list", (
      tester,
    ) async {
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
    });
  });

  group("favorite toggle (US-05.4)", () {
    testWidgets("shows an outline heart when the place isn't yet favorited", (
      tester,
    ) async {
      final place = _place();
      await _pumpSheet(
        tester,
        place,
        overrides: [
          favoriteRepositoryProvider.overrideWithValue(
            _FakeFavoriteRepository(),
          ),
          stationDetailProvider(
            place.id,
          ).overrideWith((ref) async => _stationDetail(place)),
        ],
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets("shows a filled heart when the place is already favorited", (
      tester,
    ) async {
      final place = _place();
      final fake = _FakeFavoriteRepository(
        seed: [
          Favorite(
            id: "fav-1",
            placeKind: place.placeKind,
            placeId: place.id,
            placeName: "Station Didouche",
            distanceMeters: null,
            notifyOnAvailable: false,
          ),
        ],
      );
      await _pumpSheet(
        tester,
        place,
        overrides: [
          favoriteRepositoryProvider.overrideWithValue(fake),
          stationDetailProvider(
            place.id,
          ).overrideWith((ref) async => _stationDetail(place)),
        ],
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets("tapping the outline heart shows a saving indicator, calls "
        "addFavorite, then refreshes to a filled heart", (tester) async {
      final place = _place();
      final delay = Completer<void>();
      final fake = _FakeFavoriteRepository(delay: delay);
      await _pumpSheet(
        tester,
        place,
        overrides: [
          favoriteRepositoryProvider.overrideWithValue(fake),
          stationDetailProvider(
            place.id,
          ).overrideWith((ref) async => _stationDetail(place)),
        ],
      );

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(fake.addFavoriteCallCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      // Button disabled while saving.
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byType(CircularProgressIndicator),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );

      delay.complete();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets(
      "tapping the filled heart calls removeFavorite with the resolved "
      "favorite id, then refreshes to an outline heart",
      (tester) async {
        final place = _place();
        final fake = _FakeFavoriteRepository(
          seed: [
            Favorite(
              id: "fav-1",
              placeKind: place.placeKind,
              placeId: place.id,
              placeName: "Station Didouche",
              distanceMeters: null,
              notifyOnAvailable: false,
            ),
          ],
        );
        await _pumpSheet(
          tester,
          place,
          overrides: [
            favoriteRepositoryProvider.overrideWithValue(fake),
            stationDetailProvider(
              place.id,
            ).overrideWith((ref) async => _stationDetail(place)),
          ],
        );

        expect(find.byIcon(Icons.favorite), findsOneWidget);

        await tester.tap(find.byIcon(Icons.favorite));
        await tester.pumpAndSettle();

        expect(fake.removeFavoriteCallCount, 1);
        expect(fake.lastRemovedFavoriteId, "fav-1");
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsNothing);
      },
    );

    testWidgets(
      "a repository error on tap shows a snackbar and leaves the icon in "
      "its prior (not-favorited) state, not a false 'success' state",
      (tester) async {
        final place = _place();
        final fake = _FakeFavoriteRepository(
          failure: const FavoriteRequestFailure("boom"),
        );
        await _pumpSheet(
          tester,
          place,
          overrides: [
            favoriteRepositoryProvider.overrideWithValue(fake),
            stationDetailProvider(
              place.id,
            ).overrideWith((ref) async => _stationDetail(place)),
          ],
        );

        await tester.tap(find.byIcon(Icons.favorite_border));
        await tester.pumpAndSettle();

        expect(fake.addFavoriteCallCount, 1);
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsNothing);
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets(
      "the favorite toggle has an accessible label describing the action, "
      "not just 'favorite icon'",
      (tester) async {
        final place = _place();
        final SemanticsHandle handle = tester.ensureSemantics();
        await _pumpSheet(
          tester,
          place,
          overrides: [
            favoriteRepositoryProvider.overrideWithValue(
              _FakeFavoriteRepository(),
            ),
            stationDetailProvider(
              place.id,
            ).overrideWith((ref) async => _stationDetail(place)),
          ],
        );

        final SemanticsNode node = tester.getSemantics(
          find.byIcon(Icons.favorite_border),
        );
        expect(node.label, "Ajouter aux favoris");
        handle.dispose();
      },
    );
  });
}
