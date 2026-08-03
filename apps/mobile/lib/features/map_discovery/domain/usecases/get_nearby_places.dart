import "../entities/coordinates.dart";
import "../entities/places_snapshot.dart";
import "../repositories/place_repository.dart";

/// Application-layer use case for FR-MAP-01 (US-01.1.1): "the user's
/// current position and all nearby places, on launch." A thin orchestration
/// over [PlaceRepository] today; the seam exists so future rules (e.g.
/// excluding out-of-service stations) land here, not in the Presentation
/// layer or the repository implementation.
class GetNearbyPlaces {
  const GetNearbyPlaces(this._repository);

  final PlaceRepository _repository;

  Future<PlacesSnapshot> call({
    required Coordinates center,
    double radiusMeters = 2000,
  }) {
    return _repository.getNearbyPlaces(
      center: center,
      radiusMeters: radiusMeters,
    );
  }
}
