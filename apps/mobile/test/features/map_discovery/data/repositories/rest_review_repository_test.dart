import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:rahati/features/map_discovery/data/datasources/review_remote_data_source.dart";
import "package:rahati/features/map_discovery/data/repositories/rest_review_repository.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart"
    show PlaceKind;
import "package:rahati/features/map_discovery/domain/repositories/review_repository.dart";

void main() {
  group("RestReviewRepository", () {
    final repo = RestReviewRepository(
      ReviewRemoteDataSource(http.Client(), baseUrl: ""),
    );

    test("submitReview maps PlaceKind.thirdPartyPlace to the hyphenated wire "
        "value and returns the mapped Review", () async {
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
      final repoWithClient = RestReviewRepository(
        ReviewRemoteDataSource(client, baseUrl: "https://api.raahti.dz"),
      );

      final review = await repoWithClient.submitReview(
        placeKind: PlaceKind.thirdPartyPlace,
        placeId: "p1",
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
    });

    test("getMyReviews always throws ReviewEndpointNotSpecifiedFailure "
        "(no listing endpoint exists)", () {
      expect(
        () => repo.getMyReviews(),
        throwsA(isA<ReviewEndpointNotSpecifiedFailure>()),
      );
    });

    test("updateReview always throws ReviewEndpointNotSpecifiedFailure", () {
      expect(
        () => repo.updateReview(reviewId: "r1", rating: 3, comment: null),
        throwsA(isA<ReviewEndpointNotSpecifiedFailure>()),
      );
    });

    test("deleteReview always throws ReviewEndpointNotSpecifiedFailure", () {
      expect(
        () => repo.deleteReview("r1"),
        throwsA(isA<ReviewEndpointNotSpecifiedFailure>()),
      );
    });
  });
}
