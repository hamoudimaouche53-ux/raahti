import "dart:math" as math;

import "../../../map_discovery/domain/entities/coordinates.dart";

/// Domain Model §4 — the one domain service the Slatoki bounded context
/// owns (Slatoki has no aggregate of its own; see
/// docs/architecture/domain-model.md#4-bounded-context-slatoki). Reuses
/// [Coordinates] from `map_discovery/domain` rather than duplicating a
/// lat/lng value type — that class's own doc comment already frames it as
/// this app's equivalent of the backend's `GeoPosition` shared-kernel
/// value object, just not yet physically relocated to a dedicated shared
/// module (no second feature needed one until this story).
///
/// Pure, stateless, framework-agnostic: no dependency on `flutter_compass`
/// or any device sensor — the live device heading is combined with this
/// calculator's output in the Presentation layer (ADR-0025).
abstract final class QiblaDirectionCalculator {
  /// The Kaaba, Masjid al-Haram, Mecca — standard published WGS84
  /// coordinates (21.422487°N, 39.826206°E), not a project-specific
  /// assumption.
  static const Coordinates kaaba = Coordinates(
    latitude: 21.422487,
    longitude: 39.826206,
  );

  /// The great-circle initial bearing (forward azimuth), in degrees
  /// [0, 360), from [from] to the Kaaba. `0` = due north, `90` = due east.
  static double bearingToMecca(Coordinates from) {
    final double lat1 = from.latitude * math.pi / 180;
    final double lat2 = kaaba.latitude * math.pi / 180;
    final double deltaLng = (kaaba.longitude - from.longitude) * math.pi / 180;

    final double y = math.sin(deltaLng) * math.cos(lat2);
    final double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);

    final double bearingRadians = math.atan2(y, x);
    final double bearingDegrees = bearingRadians * 180 / math.pi;
    return (bearingDegrees + 360) % 360;
  }
}
