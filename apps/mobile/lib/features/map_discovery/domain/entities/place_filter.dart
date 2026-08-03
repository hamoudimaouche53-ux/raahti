import "place.dart";

/// The FR-MAP-05 quick-filter chip categories (All / Free WC / Paid WC /
/// RAHETI Units / Slatoki). Deliberately mirrors only what
/// docs/srs/SRS.md#FR-MAP-05 defines — no accessibility (PMR) or
/// availability (open-now) category exists here, since those are not
/// defined anywhere as a *filter*, only as [Place.tags] shown on the
/// place-detail sheet (SCR-005/006) — see ADR-0021.
enum PlaceCategory { free, paid, rahatiUnit, slatoki }

/// A single-select distance cap, layered onto the already-approved
/// `radiusMeters` query parameter (docs/api/openapi.yaml, `GET
/// /places/nearby`) rather than a new backend concept. `any` means no cap.
enum DistanceFilter {
  any(null),
  under1km(1000),
  under5km(5000);

  const DistanceFilter(this.maxMeters);

  /// `null` for [any].
  final double? maxMeters;
}

/// Composable map-filtering criteria (US-01.1.4/US-01.1.5) — a pure value
/// object, held as Riverpod state ([PlaceFilterNotifier]) and applied by
/// [filterPlaces]. Every dimension is independently optional; an empty/
/// default [PlaceFilter] matches everything.
class PlaceFilter {
  const PlaceFilter({
    this.searchQuery = "",
    this.categories = const <PlaceCategory>{},
    this.distance = DistanceFilter.any,
  });

  /// Raw (not yet trimmed/lowercased) search text. Debouncing happens in the
  /// presentation layer (the search bar widget) before this is set, so every
  /// value reaching this object is already meant to be applied immediately.
  final String searchQuery;

  /// Selected category chips. Empty means "no category restriction" (the
  /// "Tout" chip's semantics) — matches every place, not zero places.
  final Set<PlaceCategory> categories;

  final DistanceFilter distance;

  bool get isActive =>
      searchQuery.trim().isNotEmpty ||
      categories.isNotEmpty ||
      distance != DistanceFilter.any;

  PlaceFilter copyWith({
    String? searchQuery,
    Set<PlaceCategory>? categories,
    DistanceFilter? distance,
  }) {
    return PlaceFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      categories: categories ?? this.categories,
      distance: distance ?? this.distance,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlaceFilter &&
      other.searchQuery == searchQuery &&
      other.distance == distance &&
      other.categories.length == categories.length &&
      other.categories.containsAll(categories);

  @override
  int get hashCode =>
      Object.hash(searchQuery, distance, Object.hashAllUnordered(categories));
}
