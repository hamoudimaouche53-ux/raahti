import "../../domain/entities/coordinates.dart";
import "../../domain/entities/favorite.dart";
import "../../domain/entities/place.dart" show PlaceKind;
import "../../domain/repositories/favorite_repository.dart";

/// **Explicitly-opt-in mock adapter** for [FavoriteRepository] — gated by
/// `AppEnv.useMockAuth`. Stateful, like `MockPaymentMethodRepository` —
/// add/remove/toggle must be reflected in a subsequent [getFavorites]
/// call for SCR-026 to be coherently demoable, including the two
/// operations [RestFavoriteRepository] can't actually perform
/// (delete/toggle) — the whole point of this mock is letting SCR-026
/// be fully interactive today, ahead of the endpoints existing.
class MockFavoriteRepository implements FavoriteRepository {
  MockFavoriteRepository({List<Favorite>? seed})
    : _favorites = seed ?? _defaultSeed();

  final List<Favorite> _favorites;

  static List<Favorite> _defaultSeed() => [
    const Favorite(
      id: "mock-fav-1",
      placeKind: PlaceKind.station,
      placeId: "s1",
      placeName: "Station Didouche",
      distanceMeters: 180,
      notifyOnAvailable: true,
    ),
    const Favorite(
      id: "mock-fav-2",
      placeKind: PlaceKind.station,
      placeId: "s2",
      placeName: "Station El Djazair",
      distanceMeters: 640,
      notifyOnAvailable: false,
    ),
  ];

  @override
  Future<List<Favorite>> getFavorites({
    Coordinates? currentPosition,
    required String languageCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<Favorite>.unmodifiable(_favorites);
  }

  @override
  Future<Favorite> addFavorite({
    required PlaceKind placeKind,
    required String placeId,
    required bool notifyOnAvailable,
    required String languageCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final Favorite added = Favorite(
      id: "mock-fav-${_favorites.length + 1}",
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
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _favorites.removeWhere((f) => f.id == favoriteId);
  }

  @override
  Future<Favorite> setNotifyOnAvailable({
    required String favoriteId,
    required bool notifyOnAvailable,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final int index = _favorites.indexWhere((f) => f.id == favoriteId);
    if (index == -1) {
      throw const FavoriteRequestFailure("No favorite matches the given id.");
    }
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
