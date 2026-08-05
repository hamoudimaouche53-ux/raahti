import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/profile/data/datasources/favorite_remote_data_source.dart";
import "package:rahati/features/profile/domain/repositories/favorite_repository.dart";

Map<String, dynamic> _favoriteJson(String id, {String? stationId}) =>
    <String, dynamic>{
      "id": id,
      "stationId": stationId,
      "thirdPartyPlaceId": stationId == null ? "p1" : null,
      "notifyOnAvailable": false,
    };

void main() {
  group("FavoriteRemoteDataSource.getFavorites", () {
    test("throws FavoriteApiNotConfiguredFailure when baseUrl is null", () {
      final source = FavoriteRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.getFavorites(),
        throwsA(isA<FavoriteApiNotConfiguredFailure>()),
      );
    });

    test("requests GET {baseUrl}/v1/users/me/favorites and parses a single page", () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode(<String, dynamic>{
            "data": [_favoriteJson("f1", stationId: "s1")],
            "nextCursor": null,
          }),
          200,
        );
      });
      final source = FavoriteRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      final favorites = await source.getFavorites();

      expect(capturedUri, Uri.parse("https://api.raahti.dz/v1/users/me/favorites"));
      expect(favorites, hasLength(1));
      expect(favorites.single.id, "f1");
      expect(favorites.single.stationId, "s1");
    });

    test(
      "follows nextCursor until exhausted, returning every favorite across pages",
      () async {
        final List<Uri> capturedUris = [];
        final client = MockClient((request) async {
          capturedUris.add(request.url);
          if (request.url.queryParameters["cursor"] == null) {
            return http.Response(
              jsonEncode(<String, dynamic>{
                "data": [_favoriteJson("f1", stationId: "s1")],
                "nextCursor": "cursor-1",
              }),
              200,
            );
          }
          if (request.url.queryParameters["cursor"] == "cursor-1") {
            return http.Response(
              jsonEncode(<String, dynamic>{
                "data": [_favoriteJson("f2", stationId: "s2")],
                "nextCursor": null,
              }),
              200,
            );
          }
          throw StateError("Unexpected cursor: ${request.url}");
        });
        final source = FavoriteRemoteDataSource(
          client,
          baseUrl: "https://api.raahti.dz",
        );

        final favorites = await source.getFavorites();

        expect(capturedUris, hasLength(2));
        expect(favorites.map((f) => f.id), ["f1", "f2"]);
      },
    );

    test("throws FavoriteRequestFailure on a non-200 response", () async {
      final client = MockClient((request) async => http.Response("", 401));
      final source = FavoriteRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      expect(
        () => source.getFavorites(),
        throwsA(isA<FavoriteRequestFailure>()),
      );
    });
  });

  group("FavoriteRemoteDataSource.addFavorite", () {
    test("throws FavoriteApiNotConfiguredFailure when baseUrl is null", () {
      final source = FavoriteRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.addFavorite(
          stationId: "s1",
          thirdPartyPlaceId: null,
          notifyOnAvailable: true,
        ),
        throwsA(isA<FavoriteApiNotConfiguredFailure>()),
      );
    });

    test(
      "POSTs {baseUrl}/v1/users/me/favorites with the station/thirdPartyPlace/"
      "notifyOnAvailable body and parses a 201 response",
      () async {
        Uri? capturedUri;
        Map<String, dynamic>? capturedBody;
        final client = MockClient((request) async {
          capturedUri = request.url;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(_favoriteJson("f1", stationId: "s1")), 201);
        });
        final source = FavoriteRemoteDataSource(
          client,
          baseUrl: "https://api.raahti.dz",
        );

        final dto = await source.addFavorite(
          stationId: "s1",
          thirdPartyPlaceId: null,
          notifyOnAvailable: true,
        );

        expect(capturedUri, Uri.parse("https://api.raahti.dz/v1/users/me/favorites"));
        expect(capturedBody, <String, dynamic>{
          "stationId": "s1",
          "thirdPartyPlaceId": null,
          "notifyOnAvailable": true,
        });
        expect(dto.id, "f1");
        expect(dto.stationId, "s1");
      },
    );

    test("throws FavoriteRequestFailure on a non-201 response", () async {
      final client = MockClient((request) async => http.Response("", 500));
      final source = FavoriteRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      expect(
        () => source.addFavorite(
          stationId: "s1",
          thirdPartyPlaceId: null,
          notifyOnAvailable: false,
        ),
        throwsA(isA<FavoriteRequestFailure>()),
      );
    });
  });
}
