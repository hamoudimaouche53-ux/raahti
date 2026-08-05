import "../../domain/entities/place.dart" show PlaceKind;
import "../../domain/entities/review.dart";
import "../../domain/repositories/review_repository.dart";

/// **Explicitly-opt-in mock adapter** for [ReviewRepository] — gated by
/// `AppEnv.useMockAuth`. Stateful, like `MockFavoriteRepository` —
/// submitting a review must appear in a subsequent [getMyReviews] call,
/// including the two operations [RestReviewRepository] can't actually
/// perform (list-mine/update/delete) — this mock is the only way to
/// demonstrate SCR-023 (My Reviews) end-to-end today.
class MockReviewRepository implements ReviewRepository {
  MockReviewRepository({List<Review>? seed})
    : _reviews = seed ?? _defaultSeed();

  final List<Review> _reviews;

  static List<Review> _defaultSeed() => [
    Review(
      id: "mock-review-1",
      rating: 5,
      comment: "Très propre, accès rapide.",
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Future<Review> submitReview({
    required PlaceKind placeKind,
    required String placeId,
    required int rating,
    required String? comment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final Review added = Review(
      id: "mock-review-${_reviews.length + 1}",
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
      rating: rating,
      comment: comment,
      createdAt: _reviews[index].createdAt,
    );
    _reviews[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _reviews.removeWhere((r) => r.id == reviewId);
  }
}
