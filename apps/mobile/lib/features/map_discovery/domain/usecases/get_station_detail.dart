import "../entities/station_detail.dart";
import "../repositories/place_detail_repository.dart";

/// Application-layer use case for US-01.2.2/US-01.2.3 (a RAHETI station).
class GetStationDetail {
  const GetStationDetail(this._repository);

  final PlaceDetailRepository _repository;

  Future<StationDetail> call(String stationId) {
    return _repository.getStationDetail(stationId);
  }
}
