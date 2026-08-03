import "../../../map_discovery/domain/entities/place.dart" show PlaceKind;

/// A saved place — `Favorite` in docs/api/openapi.yaml,
/// `FAVORITE` in docs/erd/erd.md §3.16 (US-05.4, FR-USR-04).
///
/// [placeKind]/[placeId] reuse `map_discovery`'s own polymorphic-target
/// vocabulary ([PlaceKind]) rather than duplicating a near-identical
/// `station`/`third_party_place` enum — same "one canonical type per
/// concept" discipline this codebase already applies everywhere else.
/// [placeName]/[distanceMeters] are denormalized onto this read-model
/// (not on the wire `Favorite` schema, which only carries bare ids) —
/// resolved by [FavoriteRepository]'s implementation, same "narrower
/// aggregate, enriched for its screen" precedent `Visit.placeName`
/// already established, so SCR-026 never needs a second per-row fetch of
/// its own.
class Favorite {
  const Favorite({
    required this.id,
    required this.placeKind,
    required this.placeId,
    required this.placeName,
    required this.distanceMeters,
    required this.notifyOnAvailable,
  });

  final String id;
  final PlaceKind placeKind;
  final String placeId;
  final String placeName;

  /// `null` when the caller's current position wasn't available at
  /// resolution time — SCR-026 omits the distance for that row rather
  /// than showing a fabricated value.
  final double? distanceMeters;
  final bool notifyOnAvailable;

  @override
  bool operator ==(Object other) =>
      other is Favorite &&
      other.id == id &&
      other.placeKind == placeKind &&
      other.placeId == placeId &&
      other.placeName == placeName &&
      other.distanceMeters == distanceMeters &&
      other.notifyOnAvailable == notifyOnAvailable;

  @override
  int get hashCode => Object.hash(
    id,
    placeKind,
    placeId,
    placeName,
    distanceMeters,
    notifyOnAvailable,
  );
}
