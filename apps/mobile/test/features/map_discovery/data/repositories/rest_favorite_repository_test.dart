import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/data/datasources/favorite_remote_data_source.dart";
import "package:rahati/features/map_discovery/data/repositories/rest_favorite_repository.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/station_detail.dart";
import "package:rahati/features/map_discovery/domain/entities/third_party_place_detail.dart";
import "package:rahati/features/map_discovery/domain/repositories/favorite_repository.dart";
import "package:rahati/features/map_discovery/domain/repositories/place_detail_repository.dart";

class _UnusedPlaceDetailRepository implements PlaceDetailRepository {
  const _UnusedPlaceDetailRepository();

  @override
  Future<StationDetail> getStationDetail(String stationId) =>
      throw UnimplementedError();

  @override
  Future<ThirdPartyPlaceDetail> getThirdPartyPlaceDetail(String placeId) =>
      throw UnimplementedError();
}

Place _place({required String id, required PlaceKind placeKind}) {
  return Place(
    id: id,
    placeKind: placeKind,
    name: const LocalizedText(
      fr: "Station F",
      ar: "Station A",
      en: "Station E",
    ),
    position: const Coordinates(latitude: 36.75, longitude: 3.05),
    pinColor: PinColor.amber,
    distanceMeters: 100,
    averageRating: null,
    reviewCount: 0,
    isFree: true,
    tags: const [],
  );
}

class _FakePlaceDetailRepository implements PlaceDetailRepository {
  const _FakePlaceDetailRepository();

  @override
  Future<StationDetail> getStationDetail(String stationId) async {
    return StationDetail(
      summary: _place(id: stationId, placeKind: PlaceKind.station),
      configuration: StationConfiguration.fixed,
      status: StationOperationalStatus.active,
      cabins: const [],
      slatokiTent: null,
    );
  }

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

    test("removeFavorite always throws FavoriteEndpointNotSpecifiedFailure "
        "(no delete endpoint exists)", () {
      expect(
        () => repo.removeFavorite("fav-1"),
        throwsA(isA<FavoriteEndpointNotSpecifiedFailure>()),
      );
    });

    test("setNotifyOnAvailable always throws "
        "FavoriteEndpointNotSpecifiedFailure (no update endpoint exists)", () {
      expect(
        () => repo.setNotifyOnAvailable(
          favoriteId: "fav-1",
          notifyOnAvailable: true,
        ),
        throwsA(isA<FavoriteEndpointNotSpecifiedFailure>()),
      );
    });

    test(
      "getFavorites resolves each favorite's placeName/position via "
      "PlaceDetailRepository and computes distanceMeters from currentPosition",
      () async {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              "data": [
                <String, dynamic>{
                  "id": "fav-1",
                  "stationId": "s1",
                  "thirdPartyPlaceId": null,
                  "notifyOnAvailable": true,
                },
              ],
              "nextCursor": null,
            }),
            200,
          );
        });
        final repoWithFakeDetail = RestFavoriteRepository(
          FavoriteRemoteDataSource(client, baseUrl: "https://api.raahti.dz"),
          const _FakePlaceDetailRepository(),
        );

        final favorites = await repoWithFakeDetail.getFavorites(
          currentPosition: const Coordinates(latitude: 36.75, longitude: 3.05),
          languageCode: "fr",
        );

        expect(favorites, hasLength(1));
        expect(favorites.single.id, "fav-1");
        expect(favorites.single.placeName, "Station F");
        expect(favorites.single.notifyOnAvailable, isTrue);
        // Same coordinates as the fake detail's position — zero distance.
        expect(favorites.single.distanceMeters, 0);
      },
    );

    test(
      "addFavorite POSTs and resolves the new favorite's placeName",
      () async {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              "id": "fav-2",
              "stationId": "s1",
              "thirdPartyPlaceId": null,
              "notifyOnAvailable": false,
            }),
            201,
          );
        });
        final repoWithFakeDetail = RestFavoriteRepository(
          FavoriteRemoteDataSource(client, baseUrl: "https://api.raahti.dz"),
          const _FakePlaceDetailRepository(),
        );

        final favorite = await repoWithFakeDetail.addFavorite(
          placeKind: PlaceKind.station,
          placeId: "s1",
          notifyOnAvailable: false,
          languageCode: "fr",
        );

        expect(favorite.id, "fav-2");
        expect(favorite.placeName, "Station F");
      },
    );
  });
}
