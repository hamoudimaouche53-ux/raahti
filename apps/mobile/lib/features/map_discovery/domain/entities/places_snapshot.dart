import "place.dart";

/// The result of a "get nearby places" read, carrying the freshness/
/// provenance metadata FR-MAP-07 requires ("last cached set of nearby
/// places with a visible data-freshness indicator") — not just a bare
/// list. Domain-owned because "is this data live or cached, and how old is
/// it" is business-relevant information the UI must always be able to
/// show, not incidental plumbing (ADR-0008, ADR-0022).
class PlacesSnapshot {
  const PlacesSnapshot({
    required this.places,
    required this.lastSyncedAt,
    required this.isFromCache,
  });

  final List<Place> places;

  /// When [places] was last successfully fetched from the backend. `null`
  /// only when [isFromCache] is true and the local cache has never been
  /// populated (first-ever launch, offline, before any successful sync).
  final DateTime? lastSyncedAt;

  /// `true` when the most recent remote fetch failed and [places] was
  /// served from the local cache instead (ADR-0008's read-cache fallback).
  final bool isFromCache;
}
