import "../entities/third_party_place_detail.dart";
import "../repositories/place_detail_repository.dart";

/// Application-layer use case for US-01.2.2 (a third-party place's
/// declarative status).
class GetThirdPartyPlaceDetail {
  const GetThirdPartyPlaceDetail(this._repository);

  final PlaceDetailRepository _repository;

  Future<ThirdPartyPlaceDetail> call(String placeId) {
    return _repository.getThirdPartyPlaceDetail(placeId);
  }
}
