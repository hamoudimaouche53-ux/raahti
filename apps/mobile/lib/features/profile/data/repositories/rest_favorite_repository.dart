import "../../../map_discovery/domain/entities/coordinates.dart";
import "../../../map_discovery/domain/entities/place.dart" show PlaceKind;
import "../../../map_discovery/domain/repositories/place_detail_repository.dart";
import "../../domain/entities/favorite.dart";
import "../../domain/repositories/favorite_repository.dart";
import "../datasources/favorite_remote_data_source.dart";
import "../dtos/favorite_dto.dart";

/// [FavoriteRepository] implementation backed by the REST API.
/// [getFavorites]/[addFavorite] call the real, specified endpoints;
/// [removeFavorite]/[setNotifyOnAvailable] always throw
/// [FavoriteEndpointNotSpecifiedFailure] (see that failure's own doc
/// comment).
///
/// [_placeDetailRepository] (`map_discovery`) resolves each favorite's
/// [Favorite.placeName]/position for [Favorite.distanceMeters] — the wire
/// `Favorite` schema only carries bare place ids (see `FavoriteDto`'s doc
/// comment), so this repository does the same kind of client-side
/// enrichment `PlaceDetailSheet` already does for cabin realtime updates,
/// just in the opposite direction (profile → map_discovery, the same
/// allowed one-directional import).
class RestFavoriteRepository implements FavoriteRepository {
  const RestFavoriteRepository(this._remote, this._placeDetailRepository);

  final FavoriteRemoteDataSource _remote;
  final PlaceDetailRepository _placeDetailRepository;

  @override
  Future<List<Favorite>> getFavorites({
    Coordinates? currentPosition,
    required String languageCode,
  }) async {
    final List<FavoriteDto> dtos = await _remote.getFavorites();
    final List<Favorite> favorites = [];
    for (final FavoriteDto dto in dtos) {
      final (String name, Coordinates position) = await _resolvePlace(
        dto.placeKind,
        dto.placeId,
        languageCode,
      );
      favorites.add(
        dto.toEntity(
          placeName: name,
          distanceMeters: currentPosition?.distanceMetersTo(position),
        ),
      );
    }
    return favorites;
  }

  Future<(String, Coordinates)> _resolvePlace(
    PlaceKind placeKind,
    String placeId,
    String languageCode,
  ) async {
    switch (placeKind) {
      case PlaceKind.station:
        final detail = await _placeDetailRepository.getStationDetail(placeId);
        return (
          detail.summary.name.forLanguageCode(languageCode),
          detail.summary.position,
        );
      case PlaceKind.thirdPartyPlace:
        final detail = await _placeDetailRepository.getThirdPartyPlaceDetail(
          placeId,
        );
        return (
          detail.summary.name.forLanguageCode(languageCode),
          detail.summary.position,
        );
    }
  }

  @override
  Future<Favorite> addFavorite({
    required PlaceKind placeKind,
    required String placeId,
    required bool notifyOnAvailable,
    required String languageCode,
  }) async {
    final dto = await _remote.addFavorite(
      stationId: placeKind == PlaceKind.station ? placeId : null,
      thirdPartyPlaceId: placeKind == PlaceKind.thirdPartyPlace
          ? placeId
          : null,
      notifyOnAvailable: notifyOnAvailable,
    );
    final (String name, _) = await _resolvePlace(
      placeKind,
      placeId,
      languageCode,
    );
    return dto.toEntity(placeName: name);
  }

  @override
  Future<void> removeFavorite(String favoriteId) async {
    throw const FavoriteEndpointNotSpecifiedFailure();
  }

  @override
  Future<Favorite> setNotifyOnAvailable({
    required String favoriteId,
    required bool notifyOnAvailable,
  }) async {
    throw const FavoriteEndpointNotSpecifiedFailure();
  }
}
