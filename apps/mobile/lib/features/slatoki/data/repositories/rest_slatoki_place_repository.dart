import "../../../map_discovery/domain/entities/coordinates.dart";
import "../../domain/entities/slatoki_place.dart";
import "../../domain/repositories/slatoki_place_repository.dart";
import "../datasources/slatoki_place_remote_data_source.dart";

/// [SlatokiPlaceRepository] implementation backed by the REST API. No cache
/// fallback — see the interface doc comment.
class RestSlatokiPlaceRepository implements SlatokiPlaceRepository {
  const RestSlatokiPlaceRepository(this._remote);

  final SlatokiPlaceRemoteDataSource _remote;

  @override
  Future<List<SlatokiPlace>> getSlatokiPlaces({
    required Coordinates center,
  }) async {
    final dtos = await _remote.fetchSlatokiPlaces(center: center);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }
}
