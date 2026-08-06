import "../../domain/entities/place.dart" show LocalizedText, PlaceKind;
import "../../domain/entities/review.dart";
import "../../domain/repositories/review_repository.dart";

/// **Explicitly-opt-in mock adapter** for [ReviewRepository] — gated by
/// `AppEnv.useMockAuth`. Stateful, like `MockFavoriteRepository` —
/// submitting a review must appear in a subsequent [getMyReviews] call.
class MockReviewRepository implements ReviewRepository {
  MockReviewRepository({List<Review>? seed})
    : _reviews = seed ?? _defaultSeed();

  final List<Review> _reviews;

  static List<Review> _defaultSeed() => [
    Review(
      id: "mock-review-1",
      placeKind: PlaceKind.station,
      placeId: "mock-station-1",
      placeName: const LocalizedText(
        fr: "Station Didouche",
        ar: "محطة ديدوش",
        en: "Didouche Station",
      ),
      rating: 5,
      comment: "Très propre, accès rapide.",
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Future<Review> submitReview({
    required PlaceKind placeKind,
    required String placeId,
    required String placeName,
    required int rating,
    required String? comment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final Review added = Review(
      id: "mock-review-${_reviews.length + 1}",
      placeKind: placeKind,
      placeId: placeId,
      placeName: LocalizedText(fr: placeName, ar: placeName, en: placeName),
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    _reviews.add(added);
    return added;
  }

  @override
  Future<List<Review>> getMyReviews() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<Review>.unmodifiable(_reviews);
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
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final int index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index == -1) {
      throw const ReviewRequestFailure("No review matches the given id.");
    }
    final Review updated = Review(
      id: reviewId,
      placeKind: placeKind,
      placeId: placeId,
      placeName: LocalizedText(fr: placeName, ar: placeName, en: placeName),
      rating: rating,
      comment: comment,
      createdAt: _reviews[index].createdAt,
    );
    _reviews[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteReview({
    required String reviewId,
    required PlaceKind placeKind,
    required String placeId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _reviews.removeWhere((r) => r.id == reviewId);
  }
}
