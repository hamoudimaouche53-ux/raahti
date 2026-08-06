import "../../domain/entities/place.dart" show LocalizedText, PlaceKind;
import "../../domain/entities/review.dart";
import "../../domain/repositories/review_repository.dart";
import "../datasources/review_remote_data_source.dart";

/// [ReviewRepository] implementation backed by the REST API — every
/// operation calls a real, specified endpoint (docs/api/openapi.yaml).
class RestReviewRepository implements ReviewRepository {
  const RestReviewRepository(this._remote);

  final ReviewRemoteDataSource _remote;

  String _wireType(PlaceKind placeKind) => switch (placeKind) {
    PlaceKind.station => "station",
    PlaceKind.thirdPartyPlace => "third-party-place",
  };

  @override
  Future<Review> submitReview({
    required PlaceKind placeKind,
    required String placeId,
    required String placeName,
    required int rating,
    required String? comment,
  }) async {
    final dto = await _remote.submitReview(
      placeType: _wireType(placeKind),
      placeId: placeId,
      rating: rating,
      comment: comment,
    );
    return dto.toEntity(
      placeKind: placeKind,
      placeId: placeId,
      placeName: LocalizedText(fr: placeName, ar: placeName, en: placeName),
    );
  }

  @override
  Future<List<Review>> getMyReviews() async {
    final dtos = await _remote.getMyReviews();
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<Review> updateReview({
    required String reviewId,
    required PlaceKind placeKind,
    required String placeId,
    required String placeName,
    required int rating,
    required String? comment,
  }) async {
    final dto = await _remote.updateReview(
      placeType: _wireType(placeKind),
      placeId: placeId,
      reviewId: reviewId,
      rating: rating,
      comment: comment,
    );
    return dto.toEntity(
      placeKind: placeKind,
      placeId: placeId,
      placeName: LocalizedText(fr: placeName, ar: placeName, en: placeName),
    );
  }

  @override
  Future<void> deleteReview({
    required String reviewId,
    required PlaceKind placeKind,
    required String placeId,
  }) async {
    await _remote.deleteReview(
      placeType: _wireType(placeKind),
      placeId: placeId,
      reviewId: reviewId,
    );
  }
}
