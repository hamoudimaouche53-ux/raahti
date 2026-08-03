import "../entities/place.dart" show PlaceKind;
import "../entities/review.dart";

sealed class ReviewRepositoryFailure implements Exception {
  const ReviewRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReviewApiNotConfiguredFailure extends ReviewRepositoryFailure {
  const ReviewApiNotConfiguredFailure()
    : super("No backend API is configured for this build.");
}

/// **API contract gap** — docs/api/openapi.yaml only specifies `POST
/// /places/{placeType}/{placeId}/reviews` (submit). There is no endpoint
/// to list a caller's own reviews (SCR-023), nor to update/delete one.
/// [RestReviewRepository.getMyReviews]/`updateReview`/`deleteReview` all
/// always throw this — distinct from [ReviewApiNotConfiguredFailure]
/// ("would work once deployed"), this means "wouldn't work even against
/// a deployed backend." Flagged in the implementation log's API Contract
/// Gaps section; natural shapes would be `GET /users/me/reviews` and
/// `PATCH`/`DELETE /reviews/{id}`.
class ReviewEndpointNotSpecifiedFailure extends ReviewRepositoryFailure {
  const ReviewEndpointNotSpecifiedFailure()
    : super(
        "No endpoint is specified in docs/api/openapi.yaml for listing, "
        "updating, or deleting an existing review.",
      );
}

class ReviewRequestFailure extends ReviewRepositoryFailure {
  const ReviewRequestFailure(super.message);
}

/// Repository port for SCR-007 (Submit Review, reached from the place
/// detail sheet) and SCR-023 (My Reviews, US-05.2).
abstract interface class ReviewRepository {
  Future<Review> submitReview({
    required PlaceKind placeKind,
    required String placeId,
    required int rating,
    required String? comment,
  });

  /// Always throws [ReviewEndpointNotSpecifiedFailure] in
  /// [RestReviewRepository] — see that failure's own doc comment.
  Future<List<Review>> getMyReviews();

  /// Always throws [ReviewEndpointNotSpecifiedFailure] in
  /// [RestReviewRepository] — see that failure's own doc comment.
  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    required String? comment,
  });

  /// Always throws [ReviewEndpointNotSpecifiedFailure] in
  /// [RestReviewRepository] — see that failure's own doc comment.
  Future<void> deleteReview(String reviewId);
}
