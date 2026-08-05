import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/access_payment/domain/entities/money.dart";
import "package:rahati/features/access_payment/presentation/screens/session_complete_screen.dart";
import "package:rahati/features/access_payment/presentation/screens/unlock_confirmation_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

Future<GoRouter> _pushViaGoRouter(
  WidgetTester tester, {
  Locale locale = const Locale("fr"),
  Stream<void>? cabinFreedStream,
  Money? amount,
}) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.accessPaymentUnlock,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.accessPaymentUnlock,
        builder: (context, state) => UnlockConfirmationScreen(
          cabinCode: "2",
          stationName: "Station Didouche",
          startedAt: DateTime(2026, 1, 1, 10),
          amount: amount,
          cabinFreedStream: cabinFreedStream ?? const Stream<void>.empty(),
          placeId: "s1",
          placeName: "Station Didouche",
        ),
      ),
      GoRoute(
        path: AppRoutePaths.sessionComplete,
        builder: (context, state) {
          final SessionCompleteArgs args =
              state.extra! as SessionCompleteArgs;
          return SessionCompleteScreen(
            amount: args.amount,
            duration: args.duration,
            placeId: args.placeId,
            placeName: args.placeName,
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.map,
        builder: (context, state) => const Scaffold(body: Text("MAP STUB")),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: RahatiTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
  await tester.pump();
  return router;
}

void main() {
  testWidgets(
    "shows the headline, cabin code, station name, and an animating "
    "progress indicator immediately",
    (tester) async {
      await _pushViaGoRouter(tester);

      expect(find.text("Cabine déverrouillée"), findsOneWidget);
      expect(find.text("Cabine 2"), findsOneWidget);
      expect(find.text("Station Didouche"), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text("Session en cours"), findsNothing);

      // Flush the animation + defensive timeout Timer so the test
      // binding doesn't flag a pending Timer at teardown.
      await tester.pump(const Duration(milliseconds: 1700));
    },
  );

  testWidgets(
    "settles into 'Session en cours' once the unlock sequence completes",
    (tester) async {
      await _pushViaGoRouter(tester);

      await tester.pump(const Duration(milliseconds: 1700));

      expect(find.text("Session en cours"), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    "the 'Session en cours' text is announced to screen readers via a "
    "live region when it replaces the progress indicator, not only if "
    "the user happens to navigate to it (US-06.4 finding F25)",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pushViaGoRouter(tester);

      await tester.pump(const Duration(milliseconds: 1700));

      final SemanticsNode node = tester.getSemantics(
        find.text("Session en cours"),
      );
      expect(node.label, "Session en cours");
      expect(
        node.flagsCollection.isLiveRegion,
        isTrue,
        reason: "the progress→session-active transition must be "
            "announced, matching this app's established live-region "
            "pattern (e.g. CabinStatusIndicator, map status banners)",
      );
      handle.dispose();
    },
  );

  testWidgets(
    "'J'ai terminé' navigates to SCR-019 (SessionCompleteScreen)",
    (tester) async {
      final GoRouter router = await _pushViaGoRouter(
        tester,
        amount: const Money(amount: "50", currency: "DZD"),
      );
      await tester.pump(const Duration(milliseconds: 1700));

      await tester.tap(find.text("J'ai terminé"));
      await tester.pumpAndSettle();

      expect(find.byType(SessionCompleteScreen), findsOneWidget);
      expect(find.text("50 DZD"), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        "/access-payment/session-complete",
      );
    },
  );

  testWidgets(
    "a cabinFreedStream event (door-sensor close) auto-navigates to "
    "SCR-019, same as 'J'ai terminé'",
    (tester) async {
      final controller = StreamController<void>();
      addTearDown(controller.close);

      await _pushViaGoRouter(tester, cabinFreedStream: controller.stream);
      await tester.pump(const Duration(milliseconds: 1700));

      expect(find.byType(SessionCompleteScreen), findsNothing);

      controller.add(null);
      await tester.pumpAndSettle();

      expect(find.byType(SessionCompleteScreen), findsOneWidget);
      // Free cabin (no amount) — SCR-019 shows "Gratuit", not an amount.
      expect(find.text("Gratuit"), findsOneWidget);
    },
  );

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pushViaGoRouter(tester, locale: const Locale("ar"));

    expect(find.text("تم فتح الكابينة"), findsOneWidget);
    expect(find.text("Station Didouche"), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1700));
  });
}
