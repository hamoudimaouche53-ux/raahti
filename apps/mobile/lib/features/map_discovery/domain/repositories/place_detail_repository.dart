import "../entities/station_detail.dart";
import "../entities/third_party_place_detail.dart";
import "place_repository.dart";

/// Repository port for the place detail sheet's full data (US-01.2.2,
/// US-01.2.3 — FR-PLC-02/03), implemented by the Data layer
/// (`RestPlaceDetailRepository` for real traffic, `MockPlaceDetailRepository`
/// as an explicitly-opt-in stand-in while no backend/IoT is deployed — see
/// ADR-0023). Reuses [PlaceRepositoryFailure] — the same failure vocabulary
/// as nearby-places fetches, since both hit the same backend.
abstract interface class PlaceDetailRepository {
  Future<StationDetail> getStationDetail(String stationId);

  Future<ThirdPartyPlaceDetail> getThirdPartyPlaceDetail(String placeId);
}
