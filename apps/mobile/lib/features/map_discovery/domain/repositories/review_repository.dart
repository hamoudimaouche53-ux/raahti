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

/// **Historical** — every `ReviewRepository` operation now has a real,
/// specified endpoint in docs/api/openapi.yaml (`GET /users/me/reviews`,
/// `PATCH`/`DELETE /places/{placeType}/{placeId}/reviews/{reviewId}`).
/// Kept only for any lingering references; no longer thrown by this
/// codebase.
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
  /// [placeName] is the caller's already-known display name for
  /// [placeId] (e.g. `SubmitReviewArgs.placeName`) — the wire `Review`
  /// response carries no place fields at all, so this repository wraps it
  /// into a same-value [Review.placeName] at the DTO→entity boundary
  /// rather than performing a second lookup purely to populate a value
  /// this call site never displays.
  Future<Review> submitReview({
    required PlaceKind placeKind,
    required String placeId,
    required String placeName,
    required int rating,
    required String? comment,
  });

  /// Every returned [Review] carries a real, server-resolved
  /// [Review.placeName] — see `MyReviewListItem`'s own doc comment in
  /// docs/api/openapi.yaml.
  Future<List<Review>> getMyReviews();

  /// The backend route is nested under the place (`PATCH
  /// /places/{placeType}/{placeId}/reviews/{reviewId}`), hence
  /// [placeKind]/[placeId] alongside [reviewId]. [placeName] is handled
  /// the same "pass the already-known display name through" way
  /// [submitReview] handles it.
  Future<Review> updateReview({
    required String reviewId,
    required PlaceKind placeKind,
    required String placeId,
    required String placeName,
    required int rating,
    required String? comment,
  });

  /// The backend route is nested under the place (`DELETE
  /// /places/{placeType}/{placeId}/reviews/{reviewId}`), hence
  /// [placeKind]/[placeId] alongside [reviewId].
  Future<void> deleteReview({
    required String reviewId,
    required PlaceKind placeKind,
    required String placeId,
  });
}
