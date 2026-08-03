import "package:drift/drift.dart";

import "../../domain/entities/coordinates.dart";
import "../../domain/entities/place.dart";
import "../local/app_database.dart";

/// A cached read of nearby places plus when they were last synced — `null`
/// timestamp means the cache has never been populated.
typedef CachedPlacesRead = ({List<Place> places, DateTime? lastSyncedAt});

/// Reads/writes the local Drift cache (ADR-0008, ADR-0022). No repository
/// interface of its own — like [DeviceLocationDataSource], this wraps a
/// single storage concern with one real implementation, consumed directly
/// by [RestPlaceRepository].
class PlaceLocalDataSource {
  PlaceLocalDataSource(this._db);

  final AppDatabase _db;

  /// Replaces the entire cache with [places] and stamps the sync time.
  /// Whole-replace (not merge/upsert-per-row) matches the domain: this
  /// cache always represents "the last successful nearby-places fetch",
  /// not an accumulating history.
  Future<void> cachePlaces(List<Place> places, DateTime syncedAt) {
    return _db.transaction(() async {
      await _db.delete(_db.cachedPlaces).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.cachedPlaces,
          places.map(_toCompanion).toList(growable: false),
        );
      });
      await _db
          .into(_db.cacheMeta)
          .insertOnConflictUpdate(
            // `id` given explicitly (always 0, the single-row convention) —
            // insertOnConflictUpdate needs the conflict target's value
            // present to detect the existing row, not just its column
            // default.
            CacheMetaCompanion.insert(
              id: const Value(0),
              lastSyncedAt: syncedAt,
            ),
          );
    });
  }

  Future<CachedPlacesRead> readCache() async {
    final List<CachedPlace> rows = await _db.select(_db.cachedPlaces).get();
    final CacheMetaData? meta = await (_db.select(
      _db.cacheMeta,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    return (
      places: rows.map(_toEntity).toList(growable: false),
      lastSyncedAt: meta?.lastSyncedAt,
    );
  }

  CachedPlacesCompanion _toCompanion(Place place) =>
      CachedPlacesCompanion.insert(
        id: place.id,
        placeKind: place.placeKind.name,
        nameFr: place.name.fr,
        nameAr: place.name.ar,
        nameEn: place.name.en,
        latitude: place.position.latitude,
        longitude: place.position.longitude,
        pinColor: place.pinColor.name,
        distanceMeters: place.distanceMeters,
        averageRating: Value(place.averageRating),
        reviewCount: place.reviewCount,
        isFree: place.isFree,
        tags: place.tags.join(","),
      );

  Place _toEntity(CachedPlace row) => Place(
    id: row.id,
    placeKind: PlaceKind.values.byName(row.placeKind),
    name: LocalizedText(fr: row.nameFr, ar: row.nameAr, en: row.nameEn),
    position: Coordinates(latitude: row.latitude, longitude: row.longitude),
    pinColor: PinColor.values.byName(row.pinColor),
    distanceMeters: row.distanceMeters,
    averageRating: row.averageRating,
    reviewCount: row.reviewCount,
    isFree: row.isFree,
    tags: row.tags.isEmpty ? const <String>[] : row.tags.split(","),
  );
}
