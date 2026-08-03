import "dart:async";

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
import "package:rahati/l10n/app_localizations.dart";

class _FakeReviewRepository implements ReviewRepository {
  _FakeReviewRepository({this.throwOnSubmit = false});
  final bool throwOnSubmit;
  int? capturedRating;
  String? capturedComment;

  @override
  Future<Review> submitReview({
    required PlaceKind placeKind,
    required String placeId,
    required int rating,
    required String? comment,
  }) async {
    if (throwOnSubmit) throw const ReviewRequestFailure("boom");
    capturedRating = rating;
    capturedComment = comment;
    return Review(
      id: "r1",
      rating: rating,
      comment: comment,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<List<Review>> getMyReviews() async => const [];

  @override
  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    required String? comment,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteReview(String reviewId) => throw UnimplementedError();
}

Future<GoRouter> _pushViaGoRouter(
  WidgetTester tester, {
  bool throwOnSubmit = false,
  Locale locale = const Locale("fr"),
}) async {
  final repo = _FakeReviewRepository(throwOnSubmit: throwOnSubmit);
  final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.map,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.map,
        builder: (context, state) => const Scaffold(body: Text("MAP STUB")),
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
  unawaited(
    router.push(
      AppRoutePaths.submitReview,
      extra: const SubmitReviewArgs(
        placeKind: PlaceKind.station,
        placeId: "s1",
        placeName: "Station Didouche",
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets("shows the place name and 5 stars, Publier disabled at 0", (
    tester,
  ) async {
    await _pushViaGoRouter(tester);

    expect(find.text("Station Didouche"), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(5));

    final FilledButton button = tester.widget(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets(
    "tapping the 3rd star fills 3 stars and enables Publier",
    (tester) async {
      await _pushViaGoRouter(tester);

      await tester.tap(find.byIcon(Icons.star_border).at(2));
      await tester.pump();

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));

      final FilledButton button = tester.widget(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    "publishing pops back to the map with the 'Avis publié' Snackbar",
    (tester) async {
      final GoRouter router = await _pushViaGoRouter(tester);

      await tester.tap(find.byIcon(Icons.star_border).at(3));
      await tester.pump();
      await tester.tap(find.text("Publier"));
      await tester.pumpAndSettle();

      expect(find.text("MAP STUB"), findsOneWidget);
      expect(find.text("Avis publié"), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        "/map",
      );
    },
  );

  testWidgets(
    "a submission failure keeps the screen open and shows the error "
    "Snackbar",
    (tester) async {
      await _pushViaGoRouter(tester, throwOnSubmit: true);

      await tester.tap(find.byIcon(Icons.star_border).first);
      await tester.pump();
      await tester.tap(find.text("Publier"));
      await tester.pumpAndSettle();

      expect(find.byType(SubmitReviewScreen), findsOneWidget);
      expect(
        find.text("Impossible d'envoyer votre avis. Réessayez."),
        findsOneWidget,
      );
    },
  );

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pushViaGoRouter(tester, locale: const Locale("ar"));

    expect(find.text("إضافة تقييم"), findsOneWidget);
  });

  testWidgets(
    "the AppBar close button is a real CloseButton, carrying Flutter's "
    "automatic localized tooltip instead of an unlabeled custom "
    "IconButton (US-06.4)",
    (tester) async {
      await _pushViaGoRouter(tester);

      expect(find.byType(CloseButton), findsOneWidget);
      final Tooltip tooltip = tester.widget<Tooltip>(
        find
            .descendant(
              of: find.byType(CloseButton),
              matching: find.byType(Tooltip),
            )
            .first,
      );
      expect(tooltip.message, isNotEmpty);
    },
  );
}
