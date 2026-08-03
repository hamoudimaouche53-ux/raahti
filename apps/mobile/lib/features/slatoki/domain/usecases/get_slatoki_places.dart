import "../../../map_discovery/domain/entities/coordinates.dart";
import "../entities/slatoki_place.dart";
import "../repositories/slatoki_place_repository.dart";

/// Application-layer use case for FR-SLK-03/04/05 — a thin orchestration
/// over [SlatokiPlaceRepository] today, mirroring `GetNearbyPlaces`'s seam
/// (map_discovery) for future rules to land here rather than in the
/// Presentation layer.
class GetSlatokiPlaces {
  const GetSlatokiPlaces(this._repository);

  final SlatokiPlaceRepository _repository;

  Future<List<SlatokiPlace>> call({required Coordinates center}) {
    return _repository.getSlatokiPlaces(center: center);
  }
}
