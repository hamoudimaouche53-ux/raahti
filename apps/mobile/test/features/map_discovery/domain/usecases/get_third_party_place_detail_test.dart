import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/station_detail.dart";
import "package:rahati/features/map_discovery/domain/entities/third_party_place_detail.dart";
import "package:rahati/features/map_discovery/domain/repositories/place_detail_repository.dart";
import "package:rahati/features/map_discovery/domain/usecases/get_third_party_place_detail.dart";

class _FakePlaceDetailRepository implements PlaceDetailRepository {
  String? lastPlaceId;

  @override
  Future<StationDetail> getStationDetail(String stationId) {
    throw UnimplementedError();
  }

  @override
  Future<ThirdPartyPlaceDetail> getThirdPartyPlaceDetail(String placeId) async {
    lastPlaceId = placeId;
    return ThirdPartyPlaceDetail(
      summary: const Place(
        id: "p1",
        placeKind: PlaceKind.thirdPartyPlace,
        name: LocalizedText(fr: "F", ar: "A", en: "E"),
        position: Coordinates(latitude: 36.75, longitude: 3.06),
        pinColor: PinColor.green,
        distanceMeters: 0,
        averageRating: null,
        reviewCount: 0,
        isFree: true,
        tags: <String>[],
      ),
      placeType: ThirdPartyPlaceType.mosque,
      declaredStatus: DeclaredStatus.open,
      statusSource: StatusSource.community,
    );
  }
}

void main() {
  test(
    "GetThirdPartyPlaceDetail delegates to the repository with the given id",
    () async {
      final repo = _FakePlaceDetailRepository();
      final usecase = GetThirdPartyPlaceDetail(repo);

      final result = await usecase("p1");

      expect(repo.lastPlaceId, "p1");
      expect(result.summary.id, "p1");
    },
  );
}
