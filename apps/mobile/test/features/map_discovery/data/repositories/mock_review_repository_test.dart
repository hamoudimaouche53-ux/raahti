import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/data/repositories/mock_review_repository.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";

void main() {
  group("MockReviewRepository", () {
    test(
      "submitReview is reflected in a subsequent getMyReviews call",
      () async {
        final repo = MockReviewRepository();
        final int before = (await repo.getMyReviews()).length;
        await repo.submitReview(
          placeKind: PlaceKind.station,
          placeId: "s1",
          placeName: "Station Test",
          rating: 4,
          comment: "Bien.",
        );
        final after = await repo.getMyReviews();
        expect(after.length, before + 1);
        expect(after.last.placeName.fr, "Station Test");
      },
    );

    test("updateReview changes rating/comment in place", () async {
      final repo = MockReviewRepository();
      final first = (await repo.getMyReviews()).first;
      final updated = await repo.updateReview(
        reviewId: first.id,
        placeKind: first.placeKind,
        placeId: first.placeId,
        placeName: "Station Test",
        rating: 1,
        comment: "Changé d'avis.",
      );
      expect(updated.rating, 1);
      expect(updated.comment, "Changé d'avis.");
    });

    test(
      "deleteReview removes it from a subsequent getMyReviews call",
      () async {
        final repo = MockReviewRepository();
        final first = (await repo.getMyReviews()).first;
        await repo.deleteReview(
          reviewId: first.id,
          placeKind: first.placeKind,
          placeId: first.placeId,
        );
        final after = await repo.getMyReviews();
        expect(after.any((r) => r.id == first.id), isFalse);
      },
    );
  });
}
