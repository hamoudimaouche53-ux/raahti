import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:rahati/features/map_discovery/data/datasources/review_remote_data_source.dart";
import "package:rahati/features/map_discovery/data/repositories/rest_review_repository.dart";
import "package:rahati/features/map_discovery/domain/repositories/review_repository.dart";

void main() {
  group("RestReviewRepository", () {
    final repo = RestReviewRepository(
      ReviewRemoteDataSource(http.Client(), baseUrl: ""),
    );

    test(
      "getMyReviews always throws ReviewEndpointNotSpecifiedFailure "
      "(no listing endpoint exists)",
      () {
        expect(
          () => repo.getMyReviews(),
          throwsA(isA<ReviewEndpointNotSpecifiedFailure>()),
        );
      },
    );

    test(
      "updateReview always throws ReviewEndpointNotSpecifiedFailure",
      () {
        expect(
          () => repo.updateReview(reviewId: "r1", rating: 3, comment: null),
          throwsA(isA<ReviewEndpointNotSpecifiedFailure>()),
        );
      },
    );

    test(
      "deleteReview always throws ReviewEndpointNotSpecifiedFailure",
      () {
        expect(
          () => repo.deleteReview("r1"),
          throwsA(isA<ReviewEndpointNotSpecifiedFailure>()),
        );
      },
    );
  });
}
