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

/// Never resolves — lets a test observe the screen's transient
/// `_submitting` state (US-06.4 finding F18), which
/// [_FakeReviewRepository]'s immediately-resolving future skips past too
/// fast to assert on.
class _PendingReviewRepository implements ReviewRepository {
  @override
  Future<Review> submitReview({
    required PlaceKind placeKind,
    required String placeId,
    required String placeName,
    required int rating,
    required String? comment,
  }) => Completer<Review>().future;

  @override
  Future<List<Review>> getMyReviews() async => const [];

  @override
  Future<Review> updateReview({
    required String reviewId,
    required PlaceKind placeKind,
    required String placeId,
    required String placeName,
    required int rating,
    required String? comment,
  }) => Completer<Review>().future;

  @override
  Future<void> deleteReview({
    required String reviewId,
    required PlaceKind placeKind,
    required String placeId,
  }) => throw UnimplementedError();
}

class _FakeReviewRepository implements ReviewRepository {
  _FakeReviewRepository({this.throwOnSubmit = false});
  final bool throwOnSubmit;
  int? capturedRating;
  String? capturedComment;
  int? capturedUpdateRating;
  String? capturedUpdateReviewId;

  @override
  Future<Review> submitReview({
    required PlaceKind placeKind,
    required String placeId,
    required String placeName,
    required int rating,
    required String? comment,
  }) async {
    if (throwOnSubmit) throw const ReviewRequestFailure("boom");
    capturedRating = rating;
    capturedComment = comment;
    return Review(
      id: "r1",
      placeKind: placeKind,
      placeId: placeId,
      placeName: LocalizedText(fr: placeName, ar: placeName, en: placeName),
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
    required PlaceKind placeKind,
    required String placeId,
    required String placeName,
    required int rating,
    required String? comment,
  }) async {
    if (throwOnSubmit) throw const ReviewRequestFailure("boom");
    capturedUpdateRating = rating;
    capturedUpdateReviewId = reviewId;
    return Review(
      id: reviewId,
      placeKind: placeKind,
      placeId: placeId,
      placeName: LocalizedText(fr: placeName, ar: placeName, en: placeName),
      rating: rating,
      comment: comment,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<void> deleteReview({
    required String reviewId,
    required PlaceKind placeKind,
    required String placeId,
  }) => throw UnimplementedError();
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

Future<(GoRouter, _FakeReviewRepository)> _pushEditViaGoRouter(
  WidgetTester tester, {
  Locale locale = const Locale("fr"),
}) async {
  final repo = _FakeReviewRepository();
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
        existingReview: ExistingReviewArgs(
          reviewId: "r1",
          rating: 2,
          comment: "Moyen",
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router, repo);
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

  testWidgets("tapping the 3rd star fills 3 stars and enables Publier", (
    tester,
  ) async {
    await _pushViaGoRouter(tester);

    await tester.tap(find.byIcon(Icons.star_border).at(2));
    await tester.pump();

    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));

    final FilledButton button = tester.widget(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

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
      expect(router.routerDelegate.currentConfiguration.uri.toString(), "/map");
    },
  );

  testWidgets("a submission failure keeps the screen open and shows the error "
      "Snackbar", (tester) async {
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
  });

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

  testWidgets(
    "the Publier button keeps its accessible name while submitting, not "
    "a bare unlabeled spinner (US-06.4 finding F18)",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final GoRouter router = GoRouter(
        initialLocation: AppRoutePaths.submitReview,
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutePaths.submitReview,
            builder: (context, state) => const SubmitReviewScreen(
              args: SubmitReviewArgs(
                placeKind: PlaceKind.station,
                placeId: "s1",
                placeName: "Station Didouche",
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reviewRepositoryProvider.overrideWithValue(
              _PendingReviewRepository(),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: RahatiTheme.light,
            locale: const Locale("fr"),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.star_border).at(2));
      await tester.pump();
      await tester.tap(find.text("Publier"));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel("Publier"), findsOneWidget);
      handle.dispose();
    },
  );

  group("edit mode (SCR-023's edit-review entry point)", () {
    testWidgets(
      "pre-fills the rating/comment and shows the edit title/button",
      (tester) async {
        await _pushEditViaGoRouter(tester);

        expect(find.text("Modifier l'avis"), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNWidgets(2));
        expect(find.text("Moyen"), findsOneWidget);
        expect(find.text("Enregistrer"), findsOneWidget);
      },
    );

    testWidgets(
      "saving calls updateReview with the existing reviewId and pops with "
      "the update Snackbar",
      (tester) async {
        final (GoRouter router, _FakeReviewRepository repo) =
            await _pushEditViaGoRouter(tester);

        await tester.tap(find.byIcon(Icons.star_border).first);
        await tester.pump();
        await tester.tap(find.text("Enregistrer"));
        await tester.pumpAndSettle();

        expect(repo.capturedUpdateReviewId, "r1");
        expect(repo.capturedUpdateRating, 3);
        expect(find.text("MAP STUB"), findsOneWidget);
        expect(find.text("Avis mis à jour"), findsOneWidget);
        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          "/map",
        );
      },
    );
  });
}
