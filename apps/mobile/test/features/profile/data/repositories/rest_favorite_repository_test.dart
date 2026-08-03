import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:rahati/features/map_discovery/domain/entities/station_detail.dart";
import "package:rahati/features/map_discovery/domain/entities/third_party_place_detail.dart";
import "package:rahati/features/map_discovery/domain/repositories/place_detail_repository.dart";
import "package:rahati/features/profile/data/datasources/favorite_remote_data_source.dart";
import "package:rahati/features/profile/data/repositories/rest_favorite_repository.dart";
import "package:rahati/features/profile/domain/repositories/favorite_repository.dart";

class _UnusedPlaceDetailRepository implements PlaceDetailRepository {
  const _UnusedPlaceDetailRepository();

  @override
  Future<StationDetail> getStationDetail(String stationId) =>
      throw UnimplementedError();

  @override
  Future<ThirdPartyPlaceDetail> getThirdPartyPlaceDetail(String placeId) =>
      throw UnimplementedError();
}

void main() {
  group("RestFavoriteRepository", () {
    final repo = RestFavoriteRepository(
      FavoriteRemoteDataSource(http.Client(), baseUrl: ""),
      const _UnusedPlaceDetailRepository(),
    );

    test(
      "removeFavorite always throws FavoriteEndpointNotSpecifiedFailure "
      "(no delete endpoint exists)",
      () {
        expect(
          () => repo.removeFavorite("fav-1"),
          throwsA(isA<FavoriteEndpointNotSpecifiedFailure>()),
        );
      },
    );

    test(
      "setNotifyOnAvailable always throws "
      "FavoriteEndpointNotSpecifiedFailure (no update endpoint exists)",
      () {
        expect(
          () => repo.setNotifyOnAvailable(
            favoriteId: "fav-1",
            notifyOnAvailable: true,
          ),
          throwsA(isA<FavoriteEndpointNotSpecifiedFailure>()),
        );
      },
    );
  });
}
