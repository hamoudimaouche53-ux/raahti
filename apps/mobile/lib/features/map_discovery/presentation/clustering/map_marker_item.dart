import "../../domain/entities/coordinates.dart";
import "../../domain/entities/place.dart";

/// A single map marker slot rendered by [MapScreen] — either one [Place]
/// or a cluster of several, as decided by [clusterPlaces].
sealed class MapMarkerItem {
  const MapMarkerItem();

  /// Where this marker renders — a real place's own position, or a
  /// cluster's centroid.
  Coordinates get position;
}

class SinglePlaceMarkerItem extends MapMarkerItem {
  const SinglePlaceMarkerItem(this.place);

  final Place place;

  @override
  Coordinates get position => place.position;
}

class PlaceClusterItem extends MapMarkerItem {
  const PlaceClusterItem({required this.position, required this.places})
    : assert(places.length > 1, "A cluster must contain more than one place");

  @override
  final Coordinates position;
  final List<Place> places;

  int get count => places.length;
}
