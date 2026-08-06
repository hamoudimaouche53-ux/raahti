import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/data/datasources/review_remote_data_source.dart";
import "package:rahati/features/map_discovery/domain/repositories/review_repository.dart";

void main() {
  group("ReviewRemoteDataSource.submitReview", () {
    test("throws ReviewApiNotConfiguredFailure when baseUrl is null", () {
      final source = ReviewRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.submitReview(
          placeType: "station",
          placeId: "s1",
          rating: 5,
          comment: null,
        ),
        throwsA(isA<ReviewApiNotConfiguredFailure>()),
      );
    });

    test("POSTs {baseUrl}/v1/places/{placeType}/{placeId}/reviews with the "
        "rating/comment body and parses a 201 response", () async {
      Uri? capturedUri;
      Map<String, dynamic>? capturedBody;
      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(<String, dynamic>{
            "id": "r1",
            "rating": 4,
            "comment": "Propre et rapide",
            "createdAt": "2026-08-01T10:00:00.000Z",
          }),
          201,
        );
      });
      final source = ReviewRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      final dto = await source.submitReview(
        placeType: "third-party-place",
        placeId: "p1",
        rating: 4,
        comment: "Propre et rapide",
      );

      expect(
        capturedUri,
        Uri.parse(
          "https://api.raahti.dz/v1/places/third-party-place/p1/reviews",
        ),
      );
      expect(capturedBody, <String, dynamic>{
        "rating": 4,
        "comment": "Propre et rapide",
      });
      expect(dto.id, "r1");
      expect(dto.rating, 4);
      expect(dto.comment, "Propre et rapide");
    });

    test("throws ReviewRequestFailure on a non-201 response", () async {
      final client = MockClient((request) async => http.Response("", 400));
      final source = ReviewRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      expect(
        () => source.submitReview(
          placeType: "station",
          placeId: "s1",
          rating: 5,
          comment: null,
        ),
        throwsA(isA<ReviewRequestFailure>()),
      );
    });

    test(
      "throws ReviewRequestFailure when the network call itself fails",
      () async {
        final client = MockClient(
          (request) async => throw Exception("offline"),
        );
        final source = ReviewRemoteDataSource(
          client,
          baseUrl: "https://api.raahti.dz",
        );

        expect(
          () => source.submitReview(
            placeType: "station",
            placeId: "s1",
            rating: 5,
            comment: null,
          ),
          throwsA(isA<ReviewRequestFailure>()),
        );
      },
    );
  });

  group("ReviewRemoteDataSource.getMyReviews", () {
    test("throws ReviewApiNotConfiguredFailure when baseUrl is null", () {
      final source = ReviewRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.getMyReviews(),
        throwsA(isA<ReviewApiNotConfiguredFailure>()),
      );
    });

    Map<String, dynamic> reviewJson(String id) => <String, dynamic>{
      "id": id,
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
    };

    test(
      "requests GET {baseUrl}/v1/users/me/reviews and parses a single page",
      () async {
        Uri? capturedUri;
        final client = MockClient((request) async {
          capturedUri = request.url;
          // Explicit UTF-8 content-type — without it, `http.Response`'s
          // default (`latin1`, per its own doc comment) can't encode the
          // fixture's Arabic place name and throws at construction time.
          return http.Response(
            jsonEncode(<String, dynamic>{
              "data": [reviewJson("r1")],
              "nextCursor": null,
            }),
            200,
            headers: <String, String>{
              "content-type": "application/json; charset=utf-8",
            },
          );
        });
        final source = ReviewRemoteDataSource(
          client,
          baseUrl: "https://api.raahti.dz",
        );

        final reviews = await source.getMyReviews();

        expect(
          capturedUri,
          Uri.parse("https://api.raahti.dz/v1/users/me/reviews"),
        );
        expect(reviews, hasLength(1));
        expect(reviews.single.id, "r1");
        expect(reviews.single.placeName.fr, "Station Didouche");
      },
    );

    test(
      "follows nextCursor until exhausted, returning every review across pages",
      () async {
        final List<Uri> capturedUris = [];
        final client = MockClient((request) async {
          capturedUris.add(request.url);
          if (request.url.queryParameters["cursor"] == null) {
            return http.Response(
              jsonEncode(<String, dynamic>{
                "data": [reviewJson("r1")],
                "nextCursor": "cursor-1",
              }),
              200,
              headers: <String, String>{
                "content-type": "application/json; charset=utf-8",
              },
            );
          }
          if (request.url.queryParameters["cursor"] == "cursor-1") {
            return http.Response(
              jsonEncode(<String, dynamic>{
                "data": [reviewJson("r2")],
                "nextCursor": null,
              }),
              200,
              headers: <String, String>{
                "content-type": "application/json; charset=utf-8",
              },
            );
          }
          throw StateError("Unexpected cursor: ${request.url}");
        });
        final source = ReviewRemoteDataSource(
          client,
          baseUrl: "https://api.raahti.dz",
        );

        final reviews = await source.getMyReviews();

        expect(capturedUris, hasLength(2));
        expect(reviews.map((r) => r.id), ["r1", "r2"]);
      },
    );

    test("throws ReviewRequestFailure on a non-200 response", () async {
      final client = MockClient((request) async => http.Response("", 401));
      final source = ReviewRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      expect(() => source.getMyReviews(), throwsA(isA<ReviewRequestFailure>()));
    });
  });

  group("ReviewRemoteDataSource.updateReview", () {
    test("throws ReviewApiNotConfiguredFailure when baseUrl is null", () {
      final source = ReviewRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.updateReview(
          placeType: "station",
          placeId: "s1",
          reviewId: "r1",
          rating: 3,
          comment: null,
        ),
        throwsA(isA<ReviewApiNotConfiguredFailure>()),
      );
    });

    test("PATCHes {baseUrl}/v1/places/{placeType}/{placeId}/reviews/{reviewId} "
        "with the rating/comment body and parses a 200 response", () async {
      Uri? capturedUri;
      Map<String, dynamic>? capturedBody;
      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
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
      final source = ReviewRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      final dto = await source.updateReview(
        placeType: "station",
        placeId: "s1",
        reviewId: "r1",
        rating: 2,
        comment: "Changé d'avis",
      );

      expect(
        capturedUri,
        Uri.parse("https://api.raahti.dz/v1/places/station/s1/reviews/r1"),
      );
      expect(capturedBody, <String, dynamic>{
        "rating": 2,
        "comment": "Changé d'avis",
      });
      expect(dto.rating, 2);
    });

    test("throws ReviewRequestFailure on a non-200 response", () async {
      final client = MockClient((request) async => http.Response("", 403));
      final source = ReviewRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      expect(
        () => source.updateReview(
          placeType: "station",
          placeId: "s1",
          reviewId: "r1",
          rating: 3,
          comment: null,
        ),
        throwsA(isA<ReviewRequestFailure>()),
      );
    });
  });

  group("ReviewRemoteDataSource.deleteReview", () {
    test("throws ReviewApiNotConfiguredFailure when baseUrl is null", () {
      final source = ReviewRemoteDataSource(http.Client(), baseUrl: null);
      expect(
        () => source.deleteReview(
          placeType: "station",
          placeId: "s1",
          reviewId: "r1",
        ),
        throwsA(isA<ReviewApiNotConfiguredFailure>()),
      );
    });

    test(
      "DELETEs {baseUrl}/v1/places/{placeType}/{placeId}/reviews/{reviewId}",
      () async {
        Uri? capturedUri;
        final client = MockClient((request) async {
          capturedUri = request.url;
          return http.Response("", 204);
        });
        final source = ReviewRemoteDataSource(
          client,
          baseUrl: "https://api.raahti.dz",
        );

        await source.deleteReview(
          placeType: "third-party-place",
          placeId: "p1",
          reviewId: "r1",
        );

        expect(
          capturedUri,
          Uri.parse(
            "https://api.raahti.dz/v1/places/third-party-place/p1/reviews/r1",
          ),
        );
      },
    );

    test("throws ReviewRequestFailure on a non-204 response", () async {
      final client = MockClient((request) async => http.Response("", 403));
      final source = ReviewRemoteDataSource(
        client,
        baseUrl: "https://api.raahti.dz",
      );

      expect(
        () => source.deleteReview(
          placeType: "station",
          placeId: "s1",
          reviewId: "r1",
        ),
        throwsA(isA<ReviewRequestFailure>()),
      );
    });
  });
}
