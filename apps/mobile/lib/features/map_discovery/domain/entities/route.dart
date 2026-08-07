import "coordinates.dart";

/// A walking route between two points, requested via the RAHATI backend's
/// `GET /v1/routes/walking` (itself a thin proxy over OSRM — see
/// `RouteRemoteDataSource`). Named `NavigationRoute`, not `Route` — the
/// obvious name clashes with `package:flutter/widgets.dart`'s own `Route<T>`
/// (Navigator's route type), which `NavigationScreen` also needs to import.
///
/// [points] are already decoded (see `decodePolyline` in
/// `core/utils/polyline_decoder.dart`) — this stays framework-agnostic
/// (plain [Coordinates], no `flutter_map`/`latlong2`), same rule
/// [Coordinates] itself documents; converting to `latlong2.LatLng` is a
/// Presentation-layer concern (`NavigationScreen`).
class NavigationRoute {
  const NavigationRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<Coordinates> points;
  final double distanceMeters;
  final double durationSeconds;
}
