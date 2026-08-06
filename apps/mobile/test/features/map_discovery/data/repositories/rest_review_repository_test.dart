import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/data/datasources/review_remote_data_source.dart";
import "package:rahati/features/map_discovery/data/repositories/rest_review_repository.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart"
    show PlaceKind;

void main() {
  group("RestReviewRepository", () {
    test("submitReview maps PlaceKind.thirdPartyPlace to the hyphenated wire "
        "value, wraps placeName into the returned Review", () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode(<String, dynamic>{
            "id": "r1",
            "rating": 5,
            "comment": null,
            "createdAt": "2026-08-01T10:00:00.000Z",
          }),
          201,
        );
      });
      final repo = RestReviewRepository(
        ReviewRemoteDataSource(client, baseUrl: "https://api.raahti.dz"),
      );

      final review = await repo.submitReview(
        placeKind: PlaceKind.thirdPartyPlace,
        placeId: "p1",
        placeName: "Mosquée El Djazair",
        rating: 5,
        comment: null,
      );

      expect(
        capturedUri,
        Uri.parse(
          "https://api.raahti.dz/v1/places/third-party-place/p1/reviews",
        ),
      );
      expect(review.id, "r1");
      expect(review.rating, 5);
      expect(review.placeKind, PlaceKind.thirdPartyPlace);
      expect(review.placeId, "p1");
      expect(review.placeName.fr, "Mosquée El Djazair");
    });

    test("getMyReviews maps every MyReviewListItemDto returned by the remote "
        "data source to a Review", () async {
      final client = MockClient((request) async {
        // Explicit UTF-8 content-type — without it, `http.Response`'s
        // default (`latin1`, per its own doc comment) can't encode the
        // fixture's Arabic place name and throws at construction time.
        return http.Response(
          jsonEncode(<String, dynamic>{
            "data": [
              <String, dynamic>{
                "id": "r1",
                "placeType": "station",
                "placeId": "s1",
                "placeName": <String, dynamic>{
                  "fr": "Station Didouche",
                  "ar": "محطة ديدوش",
                  "en": "Didouche Station",
                },
                "rating": 4,
                "comment": "Propre",
                "createdAt": "2026-08-01T10:00:00.000Z",
              },
            ],
            "nextCursor": null,
          }),
          200,
          headers: <String, String>{
            "content-type": "application/json; charset=utf-8",
          },
        );
      });
      final repo = RestReviewRepository(
        ReviewRemoteDataSource(client, baseUrl: "https://api.raahti.dz"),
      );

      final reviews = await repo.getMyReviews();

      expect(reviews, hasLength(1));
      expect(reviews.single.placeName.fr, "Station Didouche");
      expect(reviews.single.placeKind, PlaceKind.station);
    });

    test("updateReview PATCHes the nested route and wraps placeName into the "
        "returned Review", () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode(<String, dynamic>{
            "id": "r1",
            "rating": 2,
            "comment": "Changé d'avis",
            "createdAt": "2026-08-01T10:00:00.000Z",
          }),
          200,
        );
      });
      final repo = RestReviewRepository(
        ReviewRemoteDataSource(client, baseUrl: "https://api.raahti.dz"),
      );

      final review = await repo.updateReview(
        reviewId: "r1",
        placeKind: PlaceKind.station,
        placeId: "s1",
        placeName: "Station Didouche",
        rating: 2,
        comment: "Changé d'avis",
      );

      expect(
        capturedUri,
        Uri.parse("https://api.raahti.dz/v1/places/station/s1/reviews/r1"),
      );
      expect(review.rating, 2);
      expect(review.placeName.fr, "Station Didouche");
    });

    test("deleteReview DELETEs the nested route", () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response("", 204);
      });
      final repo = RestReviewRepository(
        ReviewRemoteDataSource(client, baseUrl: "https://api.raahti.dz"),
      );

      await repo.deleteReview(
        reviewId: "r1",
        placeKind: PlaceKind.thirdPartyPlace,
        placeId: "p1",
      );

      expect(
        capturedUri,
        Uri.parse(
          "https://api.raahti.dz/v1/places/third-party-place/p1/reviews/r1",
        ),
      );
    });
  });
}
