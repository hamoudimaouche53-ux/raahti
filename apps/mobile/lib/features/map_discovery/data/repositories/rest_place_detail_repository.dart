import "../../domain/entities/station_detail.dart";
import "../../domain/entities/third_party_place_detail.dart";
import "../../domain/repositories/place_detail_repository.dart";
import "../datasources/place_detail_remote_data_source.dart";

/// [PlaceDetailRepository] implementation backed by the REST API — the
/// production default (see `placeDetailRepositoryProvider`). Genuinely
/// live: no offline cache and no mock fallback here (unlike
/// [RestPlaceRepository]'s nearby-places cache) — the place detail sheet
/// is opened on demand for one place, not shown persistently while
/// offline, so ADR-0008's read-cache scope doesn't extend to it. On
/// failure, the sheet shows an honest error state (see
/// `PlaceDetailSheet`) exactly like every other unconfigured-backend case
/// in this codebase.
class RestPlaceDetailRepository implements PlaceDetailRepository {
  const RestPlaceDetailRepository(this._remote);

  final PlaceDetailRemoteDataSource _remote;

  @override
  Future<StationDetail> getStationDetail(String stationId) async {
    final dto = await _remote.fetchStationDetail(stationId);
    return dto.toEntity();
  }

  @override
  Future<ThirdPartyPlaceDetail> getThirdPartyPlaceDetail(String placeId) async {
    final dto = await _remote.fetchThirdPartyPlaceDetail(placeId);
    return dto.toEntity();
  }
}
