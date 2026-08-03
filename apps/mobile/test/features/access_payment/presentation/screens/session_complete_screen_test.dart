import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/access_payment/domain/entities/money.dart";
import "package:rahati/features/access_payment/presentation/screens/session_complete_screen.dart";
import "package:rahati/features/map_discovery/presentation/screens/submit_review_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

Future<GoRouter> _pushViaGoRouter(
  WidgetTester tester, {
  Money? amount,
  Duration duration = const Duration(minutes: 12),
  Locale locale = const Locale("fr"),
}) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.sessionComplete,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.sessionComplete,
        builder: (context, state) => SessionCompleteScreen(
          amount: amount,
          duration: duration,
          placeId: "s1",
          placeName: "Station Didouche",
        ),
      ),
      GoRoute(
        path: AppRoutePaths.submitReview,
        builder: (context, state) {
          final SubmitReviewArgs args = state.extra! as SubmitReviewArgs;
          return SubmitReviewScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutePaths.map,
        builder: (context, state) => const Scaffold(body: Text("MAP STUB")),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        theme: RahatiTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    ),
  );
  await tester.pump();
  return router;
}

void main() {
  testWidgets("shows the headline and amount for a paid session", (
    tester,
  ) async {
    await _pushViaGoRouter(
      tester,
      amount: const Money(amount: "50", currency: "DZD"),
      duration: const Duration(minutes: 12),
    );

    expect(find.text("Session terminée"), findsOneWidget);
    expect(find.text("50 DZD"), findsOneWidget);
    expect(find.text("12 minutes"), findsOneWidget);
    expect(find.text("Gratuit"), findsNothing);
  });

  testWidgets("shows 'Gratuit' instead of an amount for a free session", (
    tester,
  ) async {
    await _pushViaGoRouter(tester, amount: null);

    expect(find.text("Gratuit"), findsOneWidget);
  });

  testWidgets("pluralizes the duration correctly (0, 1, N minutes)", (
    tester,
  ) async {
    await _pushViaGoRouter(tester, duration: const Duration(seconds: 30));
    expect(find.text("Moins d'une minute"), findsOneWidget);

    await _pushViaGoRouter(tester, duration: const Duration(minutes: 1));
    expect(find.text("1 minute"), findsOneWidget);
  });

  testWidgets("'Laisser un avis' navigates to SCR-007 (SubmitReviewScreen)", (
    tester,
  ) async {
    await _pushViaGoRouter(tester);

    await tester.tap(find.text("Laisser un avis"));
    await tester.pumpAndSettle();

    expect(find.byType(SubmitReviewScreen), findsOneWidget);
    expect(find.text("Station Didouche"), findsOneWidget);
  });

  testWidgets("'Retour à la carte' returns to the map", (tester) async {
    final GoRouter router = await _pushViaGoRouter(tester);

    await tester.tap(find.text("Retour à la carte"));
    await tester.pumpAndSettle();

    expect(find.text("MAP STUB"), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.toString(), "/map");
  });

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pushViaGoRouter(tester, locale: const Locale("ar"));

    expect(find.text("انتهت الجلسة"), findsOneWidget);
    expect(find.text("مجاني"), findsOneWidget);
  });
}
