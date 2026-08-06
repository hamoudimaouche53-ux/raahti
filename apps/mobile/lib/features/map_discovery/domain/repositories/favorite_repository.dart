import "../entities/coordinates.dart";
import "../entities/favorite.dart";
import "../entities/place.dart" show PlaceKind;

sealed class FavoriteRepositoryFailure implements Exception {
  const FavoriteRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class FavoriteApiNotConfiguredFailure extends FavoriteRepositoryFailure {
  const FavoriteApiNotConfiguredFailure()
    : super("No backend API is configured for this build.");
}

/// **Historical** — `DELETE`/`PATCH /users/me/favorites/{id}` are now
/// specified in docs/api/openapi.yaml and implemented by
/// [RestFavoriteRepository.removeFavorite]/`setNotifyOnAvailable`. Kept
/// only for any lingering references; no longer thrown by this codebase.
class FavoriteEndpointNotSpecifiedFailure extends FavoriteRepositoryFailure {
  const FavoriteEndpointNotSpecifiedFailure()
    : super(
        "No endpoint is specified in docs/api/openapi.yaml for removing "
        "or updating an existing favorite.",
      );
}

class FavoriteRequestFailure extends FavoriteRepositoryFailure {
  const FavoriteRequestFailure(super.message);
}

/// Repository port for SCR-026 (Favorites List, US-05.4).
abstract interface class FavoriteRepository {
  /// [currentPosition] resolves each favorite's [Favorite.distanceMeters]
  /// — `null` when the caller doesn't have a current position yet.
  /// [languageCode] resolves each favorite's [Favorite.placeName] from
  /// the underlying place's `LocalizedText` (fr/ar/en) — same "resolve at
  /// the repository, not the widget" reasoning `Visit.placeName` already
  /// follows.
  Future<List<Favorite>> getFavorites({
    Coordinates? currentPosition,
    required String languageCode,
  });

  Future<Favorite> addFavorite({
    required PlaceKind placeKind,
    required String placeId,
    required bool notifyOnAvailable,
    required String languageCode,
  });

  Future<void> removeFavorite(String favoriteId);

  Future<Favorite> setNotifyOnAvailable({
    required String favoriteId,
    required bool notifyOnAvailable,
  });
}
