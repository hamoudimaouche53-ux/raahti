import "../../../map_discovery/domain/entities/coordinates.dart";
import "../../../map_discovery/domain/entities/place.dart" show PlaceKind;
import "../entities/favorite.dart";

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

/// **API contract gap** — docs/api/openapi.yaml specifies `GET`/`POST
/// /users/me/favorites` but no `DELETE`/`PATCH` for an individual
/// favorite. [RestFavoriteRepository.removeFavorite] and
/// [RestFavoriteRepository.setNotifyOnAvailable] both always throw this —
/// unlike [FavoriteApiNotConfiguredFailure] ("would work once deployed"),
/// this means "wouldn't work even against a deployed backend, the
/// endpoint isn't specified." Flagged in the implementation log's API
/// Contract Gaps section; natural shapes would be
/// `DELETE /users/me/favorites/{id}` and
/// `PATCH /users/me/favorites/{id}`.
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

  /// Always throws [FavoriteEndpointNotSpecifiedFailure] in
  /// [RestFavoriteRepository] — see that failure's own doc comment.
  Future<void> removeFavorite(String favoriteId);

  /// Always throws [FavoriteEndpointNotSpecifiedFailure] in
  /// [RestFavoriteRepository] — see that failure's own doc comment.
  Future<Favorite> setNotifyOnAvailable({
    required String favoriteId,
    required bool notifyOnAvailable,
  });
}
