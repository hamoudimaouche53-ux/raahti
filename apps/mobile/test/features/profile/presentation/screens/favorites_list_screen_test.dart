import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/favorite.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/repositories/favorite_repository.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_detail_providers.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_providers.dart";
import "package:rahati/features/profile/presentation/screens/favorites_list_screen.dart";
import "package:rahati/features/profile/presentation/screens/notification_settings_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

class _FakeFavoriteRepository implements FavoriteRepository {
  _FakeFavoriteRepository(this._favorites);
  final List<Favorite> _favorites;

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
  }) => throw UnimplementedError();

  @override
  Future<void> removeFavorite(String favoriteId) => throw UnimplementedError();

  @override
  Future<Favorite> setNotifyOnAvailable({
    required String favoriteId,
    required bool notifyOnAvailable,
  }) async {
    final int index = _favorites.indexWhere((f) => f.id == favoriteId);
    final Favorite current = _favorites[index];
    final Favorite updated = Favorite(
      id: current.id,
      placeKind: current.placeKind,
      placeId: current.placeId,
      placeName: current.placeName,
      distanceMeters: current.distanceMeters,
      notifyOnAvailable: notifyOnAvailable,
    );
    _favorites[index] = updated;
    return updated;
  }
}

Future<GoRouter> _pushViaGoRouter(
  WidgetTester tester, {
  required List<Favorite> favorites,
  Locale locale = const Locale("fr"),
}) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.profileFavorites,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.profileFavorites,
        builder: (context, state) => const FavoritesListScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profileNotificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favoriteRepositoryProvider.overrideWithValue(
          _FakeFavoriteRepository(favorites),
        ),
        userPositionProvider.overrideWith(
          (ref) async =>
              const Coordinates(latitude: 36.7538, longitude: 3.0588),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: RahatiTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets("shows the empty state when there are no favorites", (
    tester,
  ) async {
    await _pushViaGoRouter(tester, favorites: const []);

    expect(
      find.text("Aucun favori — ajoutez-en depuis la fiche lieu"),
      findsOneWidget,
    );
  });

  testWidgets("shows each favorite's name, distance, and notify switch", (
    tester,
  ) async {
    await _pushViaGoRouter(
      tester,
      favorites: const [
        Favorite(
          id: "fav-1",
          placeKind: PlaceKind.station,
          placeId: "s1",
          placeName: "Station Didouche",
          distanceMeters: 180,
          notifyOnAvailable: true,
        ),
      ],
    );

    expect(find.text("Station Didouche"), findsOneWidget);
    expect(find.text("180 m"), findsOneWidget);
    final Switch toggle = tester.widget(find.byType(Switch));
    expect(toggle.value, isTrue);
  });

  testWidgets("toggling the switch calls setNotifyOnAvailable and persists", (
    tester,
  ) async {
    await _pushViaGoRouter(
      tester,
      favorites: [
        const Favorite(
          id: "fav-1",
          placeKind: PlaceKind.station,
          placeId: "s1",
          placeName: "Station Didouche",
          distanceMeters: 180,
          notifyOnAvailable: false,
        ),
      ],
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final Switch toggle = tester.widget(find.byType(Switch));
    expect(toggle.value, isTrue);
  });

  testWidgets("the settings AppBar action navigates to SCR-027 "
      "(NotificationSettingsScreen)", (tester) async {
    await _pushViaGoRouter(tester, favorites: const []);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationSettingsScreen), findsOneWidget);
  });

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pushViaGoRouter(
      tester,
      favorites: const [],
      locale: const Locale("ar"),
    );

    expect(find.text("المفضلة"), findsOneWidget);
  });

  testWidgets("the AppBar back button is a real BackButton, carrying Flutter's "
      "automatic localized tooltip instead of an unlabeled custom "
      "IconButton (US-06.4)", (tester) async {
    await _pushViaGoRouter(tester, favorites: const []);

    expect(find.byType(BackButton), findsOneWidget);
    final Tooltip tooltip = tester.widget<Tooltip>(
      find
          .descendant(
            of: find.byType(BackButton),
            matching: find.byType(Tooltip),
          )
          .first,
    );
    expect(tooltip.message, isNotEmpty);
  });
}
