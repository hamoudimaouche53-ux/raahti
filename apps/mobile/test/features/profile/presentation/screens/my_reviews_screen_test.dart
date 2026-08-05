import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/review.dart";
import "package:rahati/features/map_discovery/domain/repositories/review_repository.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_detail_providers.dart";
import "package:rahati/features/profile/presentation/screens/my_reviews_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

class _FakeReviewRepository implements ReviewRepository {
  _FakeReviewRepository(this._reviews);
  final List<Review> _reviews;

  @override
  Future<Review> submitReview({
    required PlaceKind placeKind,
    required String placeId,
    required int rating,
    required String? comment,
  }) => throw UnimplementedError();

  @override
  Future<List<Review>> getMyReviews() async =>
      List<Review>.unmodifiable(_reviews);

  @override
  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    required String? comment,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteReview(String reviewId) async {
    _reviews.removeWhere((r) => r.id == reviewId);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Review> reviews,
  Locale locale = const Locale("fr"),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reviewRepositoryProvider.overrideWithValue(
          _FakeReviewRepository(reviews),
        ),
      ],
      child: MaterialApp(
        theme: RahatiTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const MyReviewsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("shows the empty state when there are no reviews", (
    tester,
  ) async {
    await _pump(tester, reviews: []);

    expect(find.text("Aucun avis pour le moment"), findsOneWidget);
  });

  testWidgets("shows a 5-star row for each review, filled up to its rating", (
    tester,
  ) async {
    await _pump(
      tester,
      reviews: [
        Review(
          id: "r1",
          rating: 3,
          comment: "Bien",
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );

    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    expect(find.textContaining("Bien"), findsOneWidget);
  });

  testWidgets("deleting a review (after confirming) removes it", (
    tester,
  ) async {
    await _pump(
      tester,
      reviews: [
        Review(
          id: "r1",
          rating: 5,
          comment: "Top",
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text("Supprimer cet avis ?"), findsOneWidget);

    await tester.tap(find.text("Supprimer"));
    await tester.pumpAndSettle();

    expect(find.text("Aucun avis pour le moment"), findsOneWidget);
  });

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pump(tester, reviews: [], locale: const Locale("ar"));

    expect(find.text("تقييماتي"), findsOneWidget);
  });

  testWidgets(
    "the star-rating row exposes the numeric rating to screen readers, "
    "not just N filled stars visually (US-06.4)",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        reviews: [
          Review(
            id: "r1",
            rating: 3,
            comment: "Bien",
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );

      expect(find.bySemanticsLabel(RegExp("3 étoiles sur 5")), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    "the delete-review icon button has an accessible tooltip, not just a "
    "bare icon (US-06.4)",
    (tester) async {
      await _pump(
        tester,
        reviews: [
          Review(
            id: "r1",
            rating: 5,
            comment: "Top",
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      );

      expect(find.byTooltip("Supprimer"), findsOneWidget);
    },
  );

  testWidgets("the AppBar back button is a real BackButton, carrying Flutter's "
      "automatic localized tooltip instead of an unlabeled custom "
      "IconButton (US-06.4)", (tester) async {
    await _pump(tester, reviews: []);

    expect(find.byType(BackButton), findsOneWidget);
    final Tooltip tooltip = tester.widget<Tooltip>(
      find
          .descendant(
            of: find.byType(BackButton),
            matching: find.byType(Tooltip),
          )
          .first,
    );
    expect(tooltip.message, isNotEmpty);
  });
}
