import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/domain/entities/place.dart";
import "package:rahati/features/map_discovery/domain/entities/review.dart";
import "package:rahati/features/map_discovery/domain/repositories/review_repository.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_detail_providers.dart";
import "package:rahati/features/map_discovery/presentation/screens/submit_review_screen.dart";
import "package:rahati/features/profile/presentation/screens/my_reviews_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

class _FakeReviewRepository implements ReviewRepository {
  _FakeReviewRepository(this._reviews);
  final List<Review> _reviews;

  @override
  Future<Review> submitReview({
    required PlaceKind placeKind,
    required String placeId,
    required String placeName,
    required int rating,
    required String? comment,
  }) => throw UnimplementedError();

  @override
  Future<List<Review>> getMyReviews() async =>
      List<Review>.unmodifiable(_reviews);

  @override
  Future<Review> updateReview({
    required String reviewId,
    required PlaceKind placeKind,
    required String placeId,
    required String placeName,
    required int rating,
    required String? comment,
  }) async {
    final int index = _reviews.indexWhere((r) => r.id == reviewId);
    final Review current = _reviews[index];
    final Review updated = Review(
      id: current.id,
      placeKind: current.placeKind,
      placeId: current.placeId,
      placeName: current.placeName,
      rating: rating,
      comment: comment,
      createdAt: current.createdAt,
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
    _reviews.removeWhere((r) => r.id == reviewId);
  }
}

Review _review({
  String id = "r1",
  int rating = 3,
  String? comment = "Bien",
  DateTime? createdAt,
  String placeName = "Station Didouche",
}) {
  return Review(
    id: id,
    placeKind: PlaceKind.station,
    placeId: "s1",
    placeName: LocalizedText(fr: placeName, ar: placeName, en: placeName),
    rating: rating,
    comment: comment,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

Future<GoRouter> _pushViaGoRouter(
  WidgetTester tester, {
  required List<Review> reviews,
  Locale locale = const Locale("fr"),
}) async {
  final repo = _FakeReviewRepository(reviews);
  final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.profileMyReviews,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.profileMyReviews,
        builder: (context, state) => const MyReviewsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.submitReview,
        builder: (context, state) {
          final SubmitReviewArgs args = state.extra! as SubmitReviewArgs;
          return SubmitReviewScreen(args: args);
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [reviewRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: router,
        theme: RahatiTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets("shows the empty state when there are no reviews", (
    tester,
  ) async {
    await _pushViaGoRouter(tester, reviews: []);

    expect(find.text("Aucun avis pour le moment"), findsOneWidget);
  });

  testWidgets("shows the resolved place name and a 5-star row for each "
      "review, filled up to its rating", (tester) async {
    await _pushViaGoRouter(tester, reviews: [_review(rating: 3)]);

    expect(find.text("Station Didouche"), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    expect(find.textContaining("Bien"), findsOneWidget);
  });

  testWidgets("deleting a review (after confirming) removes it", (
    tester,
  ) async {
    await _pushViaGoRouter(tester, reviews: [_review()]);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text("Supprimer cet avis ?"), findsOneWidget);

    await tester.tap(find.text("Supprimer"));
    await tester.pumpAndSettle();

    expect(find.text("Aucun avis pour le moment"), findsOneWidget);
  });

  testWidgets(
    "tapping the edit action opens SubmitReviewScreen pre-filled, and "
    "saving reflects the change back on the list",
    (tester) async {
      await _pushViaGoRouter(
        tester,
        reviews: [_review(rating: 2, comment: "Moyen")],
      );

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(SubmitReviewScreen), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.star_border).first);
      await tester.pump();
      await tester.tap(find.text("Enregistrer"));
      await tester.pumpAndSettle();

      expect(find.byType(MyReviewsScreen), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNWidgets(3));
    },
  );

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pushViaGoRouter(tester, reviews: [], locale: const Locale("ar"));

    expect(find.text("تقييماتي"), findsOneWidget);
  });

  testWidgets(
    "the star-rating row exposes the numeric rating to screen readers, "
    "not just N filled stars visually (US-06.4)",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pushViaGoRouter(tester, reviews: [_review(rating: 3)]);

      expect(find.bySemanticsLabel(RegExp("3 étoiles sur 5")), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    "the delete-review icon button has an accessible tooltip, not just a "
    "bare icon (US-06.4)",
    (tester) async {
      await _pushViaGoRouter(tester, reviews: [_review()]);

      expect(find.byTooltip("Supprimer"), findsOneWidget);
      expect(find.byTooltip("Modifier"), findsOneWidget);
    },
  );

  testWidgets("the AppBar back button is a real BackButton, carrying Flutter's "
      "automatic localized tooltip instead of an unlabeled custom "
      "IconButton (US-06.4)", (tester) async {
    await _pushViaGoRouter(tester, reviews: []);

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
