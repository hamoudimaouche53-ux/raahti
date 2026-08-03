import "dart:math" as math;

import "../../domain/entities/coordinates.dart";
import "../../domain/entities/place.dart";
import "map_marker_item.dart";

/// Greedy, pixel-radius-based marker clustering for US-01.1.2 ("Support
/// clustering when appropriate").
///
/// No `flutter_map`-ecosystem clustering package could be added: every
/// clustering plugin found on pub.dev (`flutter_map_marker_cluster`,
/// `flutter_map_marker_cluster_plus`, `_2`, `flutter_map_supercluster`) is
/// pinned to `latlong2 ^0.8.x`/`^0.9.x`, incompatible with the
/// `latlong2 ^0.10.1` this project already depends on transitively via
/// `flutter_map 8.3.1` (ADR-0019) — downgrading `flutter_map` to satisfy an
/// older clustering plugin would undo a working, tested, screenshotted
/// integration from Feature 1, which this phase's "keep the application
/// runnable after every completed story" rule weighs against. This
/// hand-rolled clusterer avoids the dependency entirely, is trivially
/// unit-testable as a pure function (see `place_clusterer_test.dart`), and
/// is small enough that maintaining it is cheaper than chasing a plugin
/// compatibility fix. Documented here rather than silently substituted.
///
/// **Algorithm**: single-link greedy clustering. Places within
/// [pixelRadius] screen pixels of an unclustered "seed" place (at the
/// given [zoom] and [referenceLatitude]) join that seed's cluster. This is
/// intentionally simple — not hierarchical/supercluster-grade — but is
/// correct, fast for the marker counts this app handles (a "nearby places"
/// query, not a whole-country dataset), and self-adjusting: the same pixel
/// radius covers a huge geographic area when zoomed out and a tiny one
/// when zoomed in, so clusters naturally dissolve into individual markers
/// as the user zooms in — "when appropriate" per the story's own wording.
List<MapMarkerItem> clusterPlaces({
  required List<Place> places,
  required double zoom,
  required double referenceLatitude,
  double pixelRadius = 60,
}) {
  if (places.isEmpty) return const <MapMarkerItem>[];

  final double clusterRadiusMeters =
      _metersPerPixel(zoom, referenceLatitude) * pixelRadius;

  final List<Place> remaining = List<Place>.from(places);
  final List<MapMarkerItem> result = <MapMarkerItem>[];

  while (remaining.isNotEmpty) {
    final Place seed = remaining.removeAt(0);
    final List<Place> group = <Place>[seed];

    remaining.removeWhere((candidate) {
      final bool withinRadius =
          seed.position.distanceMetersTo(candidate.position) <=
          clusterRadiusMeters;
      if (withinRadius) group.add(candidate);
      return withinRadius;
    });

    result.add(
      group.length == 1
          ? SinglePlaceMarkerItem(group.single)
          : PlaceClusterItem(position: _centroid(group), places: group),
    );
  }

  return result;
}

/// Standard Web Mercator meters-per-pixel formula at a given [zoom] and
/// [latitudeDegrees] (tile size 256px, per the OSM/Web-Mercator convention
/// this app's `TileLayer` already uses — ADR-0019).
double _metersPerPixel(double zoom, double latitudeDegrees) {
  const double earthCircumferenceMeters = 40075016.686;
  final double latitudeRadians = latitudeDegrees * math.pi / 180;
  return earthCircumferenceMeters *
      math.cos(latitudeRadians) /
      (256 * math.pow(2, zoom));
}

Coordinates _centroid(List<Place> group) {
  final double avgLat =
      group.map((p) => p.position.latitude).reduce((a, b) => a + b) /
      group.length;
  final double avgLng =
      group.map((p) => p.position.longitude).reduce((a, b) => a + b) /
      group.length;
  return Coordinates(latitude: avgLat, longitude: avgLng);
}
