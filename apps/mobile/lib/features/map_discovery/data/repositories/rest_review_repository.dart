import "../../domain/entities/place.dart" show PlaceKind;
import "../../domain/entities/review.dart";
import "../../domain/repositories/review_repository.dart";
import "../datasources/review_remote_data_source.dart";

/// [ReviewRepository] implementation backed by the REST API.
/// [submitReview] calls the real, specified endpoint;
/// [getMyReviews]/[updateReview]/[deleteReview] always throw
/// [ReviewEndpointNotSpecifiedFailure] (see that failure's own doc
/// comment).
class RestReviewRepository implements ReviewRepository {
  const RestReviewRepository(this._remote);

  final ReviewRemoteDataSource _remote;

  @override
  Future<Review> submitReview({
    required PlaceKind placeKind,
    required String placeId,
    required int rating,
    required String? comment,
  }) async {
    final dto = await _remote.submitReview(
      placeType: switch (placeKind) {
        PlaceKind.station => "station",
        PlaceKind.thirdPartyPlace => "third-party-place",
      },
      placeId: placeId,
      rating: rating,
      comment: comment,
    );
    return dto.toEntity();
  }

  @override
  Future<List<Review>> getMyReviews() async {
    throw const ReviewEndpointNotSpecifiedFailure();
  }

  @override
  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    required String? comment,
  }) async {
    throw const ReviewEndpointNotSpecifiedFailure();
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    throw const ReviewEndpointNotSpecifiedFailure();
  }
}
