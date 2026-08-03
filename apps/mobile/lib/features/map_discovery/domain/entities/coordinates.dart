import "dart:math" as math;

/// A WGS84 geographic point, framework-agnostic (no `flutter_map`/`latlong2`
/// import here — those are Presentation-layer concerns; the Domain layer
/// only knows plain lat/lng doubles). Mirrors the backend's `GeoPosition`
/// shared-kernel value object
/// (docs/architecture/module-dependency-diagram.md §2) and the API's
/// GeoJSON `[lng, lat]` convention (docs/api/api-architecture.md §4),
/// exposed here with named fields for readability.
class Coordinates {
  const Coordinates({required this.latitude, required this.longitude})
    : assert(
        latitude >= -90 && latitude <= 90,
        "latitude must be in [-90, 90]",
      ),
      assert(
        longitude >= -180 && longitude <= 180,
        "longitude must be in [-180, 180]",
      );

  final double latitude;
  final double longitude;

  static const double _earthRadiusMeters = 6371000;

  /// Great-circle distance to [other], in meters (Haversine formula).
  ///
  /// Pure domain geometry — used by both the map-marker clusterer
  /// (US-01.1.2, presentation-layer) and, in a future story, distance
  /// filtering (this phase's "Search and filtering" requirement).
  double distanceMetersTo(Coordinates other) {
    final double lat1 = latitude * math.pi / 180;
    final double lat2 = other.latitude * math.pi / 180;
    final double dLat = (other.latitude - latitude) * math.pi / 180;
    final double dLng = (other.longitude - longitude) * math.pi / 180;

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  @override
  bool operator ==(Object other) =>
      other is Coordinates &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => "Coordinates($latitude, $longitude)";
}
