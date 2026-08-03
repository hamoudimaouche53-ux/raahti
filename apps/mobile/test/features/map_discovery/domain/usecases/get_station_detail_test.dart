import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/station_detail.dart";
import "package:rahati/features/map_discovery/domain/entities/third_party_place_detail.dart";
import "package:rahati/features/map_discovery/domain/repositories/place_detail_repository.dart";
import "package:rahati/features/map_discovery/domain/usecases/get_station_detail.dart";

class _FakePlaceDetailRepository implements PlaceDetailRepository {
  String? lastStationId;

  @override
  Future<StationDetail> getStationDetail(String stationId) async {
    lastStationId = stationId;
    return StationDetail(
      summary: const Place(
        id: "s1",
        placeKind: PlaceKind.station,
        name: LocalizedText(fr: "F", ar: "A", en: "E"),
        position: Coordinates(latitude: 36.75, longitude: 3.06),
        pinColor: PinColor.amber,
        distanceMeters: 0,
        averageRating: null,
        reviewCount: 0,
        isFree: false,
        tags: <String>[],
      ),
      configuration: StationConfiguration.fixed,
      status: StationOperationalStatus.active,
      cabins: const [],
      slatokiTent: null,
    );
  }

  @override
  Future<ThirdPartyPlaceDetail> getThirdPartyPlaceDetail(String placeId) {
    throw UnimplementedError();
  }
}

void main() {
  test(
    "GetStationDetail delegates to the repository with the given id",
    () async {
      final repo = _FakePlaceDetailRepository();
      final usecase = GetStationDetail(repo);

      final result = await usecase("s1");

      expect(repo.lastStationId, "s1");
      expect(result.summary.id, "s1");
    },
  );
}
