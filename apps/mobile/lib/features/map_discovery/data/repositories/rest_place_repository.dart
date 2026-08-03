import "../../domain/entities/coordinates.dart";
import "../../domain/entities/places_snapshot.dart";
import "../../domain/repositories/place_repository.dart";
import "../datasources/place_local_data_source.dart";
import "../datasources/place_remote_data_source.dart";

/// [PlaceRepository] implementation backed by the REST API
/// ([PlaceRemoteDataSource]), with a local-cache fallback
/// ([PlaceLocalDataSource]) per ADR-0008/ADR-0022: a successful fetch is
/// written to cache; a failed fetch falls back to reading it, so FR-MAP-07's
/// "last cached set of nearby places with a freshness indicator" is served
/// instead of an error whenever there's anything usable to show.
class RestPlaceRepository implements PlaceRepository {
  const RestPlaceRepository(this._remote, this._local);

  final PlaceRemoteDataSource _remote;
  final PlaceLocalDataSource _local;

  @override
  Future<PlacesSnapshot> getNearbyPlaces({
    required Coordinates center,
    double radiusMeters = 2000,
  }) async {
    try {
      final dtos = await _remote.fetchNearbyPlaces(
        center: center,
        radiusMeters: radiusMeters,
      );
      final places = dtos.map((dto) => dto.toEntity()).toList(growable: false);
      final DateTime syncedAt = DateTime.now();
      await _local.cachePlaces(places, syncedAt);
      return PlacesSnapshot(
        places: places,
        lastSyncedAt: syncedAt,
        isFromCache: false,
      );
    } on PlaceRepositoryFailure {
      final CachedPlacesRead cached = await _local.readCache();
      if (cached.lastSyncedAt == null) {
        // Nothing usable in the cache either — the original failure is
        // more informative than a generic "no cache" message.
        rethrow;
      }
      return PlacesSnapshot(
        places: cached.places,
        lastSyncedAt: cached.lastSyncedAt,
        isFromCache: true,
      );
    }
  }
}
