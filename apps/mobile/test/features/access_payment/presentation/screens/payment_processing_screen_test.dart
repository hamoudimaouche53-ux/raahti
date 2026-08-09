import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/access_payment/domain/entities/access_session.dart";
import "package:rahati/features/access_payment/domain/entities/access_session_status.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_repository.dart";
import "package:rahati/features/access_payment/presentation/providers/payment_providers.dart";
import "package:rahati/features/access_payment/presentation/screens/payment_processing_screen.dart";
import "package:rahati/features/access_payment/presentation/screens/qr_scanner_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

class _FakePaymentRepository implements PaymentRepository {
  _FakePaymentRepository({this.failure, this.delay});

  final PaymentRepositoryFailure? failure;
  final Completer<void>? delay;

  static final AccessSession _session = AccessSession(
    id: "session-1",
    cabinId: "cabin-1",
    status: AccessSessionStatus.unlocked,
    startedAt: DateTime(2026),
    unlockedAt: DateTime(2026),
  );

  @override
  Future<AccessSession> requestPayment({
    required String accessSessionId,
    required String? paymentMethodId,
    required bool applyEmergencyDiscount,
    required String idempotencyKey,
  }) async {
    final Completer<void>? d = delay;
    if (d != null) await d.future;
    final PaymentRepositoryFailure? f = failure;
    if (f != null) throw f;
    return _session;
  }
}

class _PushResult {
  Object? value;
  bool completed = false;
}

Future<_PushResult> _pumpNavigatorHarness(
  WidgetTester tester,
  PaymentRepositoryFailure? failure, {
  Completer<void>? delay,
}) async {
  final _PushResult result = _PushResult();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        paymentRepositoryProvider.overrideWithValue(
          _FakePaymentRepository(failure: failure, delay: delay),
        ),
      ],
      child: MaterialApp(
        theme: RahatiTheme.light,
        locale: const Locale("fr"),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result.value = await Navigator.of(context).push<Object>(
                MaterialPageRoute(
                  builder: (_) => const PaymentProcessingScreen(
                    accessSessionId: "session-1",
                    paymentMethodId: "pm-1",
                  ),
                ),
              );
              result.completed = true;
            },
            child: const Text("push"),
          ),
        ),
      ),
    ),
  );
  return result;
}

Future<GoRouter> _pushViaGoRouter(
  WidgetTester tester,
  PaymentRepositoryFailure? failure,
) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.accessPaymentProcessing,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.accessPaymentProcessing,
        builder: (context, state) => const PaymentProcessingScreen(
          accessSessionId: "session-1",
          paymentMethodId: "pm-1",
        ),
      ),
      GoRoute(
        path: AppRoutePaths.accessPaymentScan,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.map,
        builder: (context, state) => const Scaffold(body: Text("MAP STUB")),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        paymentRepositoryProvider.overrideWithValue(
          _FakePaymentRepository(failure: failure),
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
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets("shows the processing message while the request is in flight", (
    tester,
  ) async {
    final delay = Completer<void>();
    addTearDown(() {
      if (!delay.isCompleted) delay.complete();
    });

    await _pumpNavigatorHarness(tester, null, delay: delay);
    await tester.tap(find.text("push"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text("Traitement du paiement..."), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets("pops with the updated AccessSession on success", (tester) async {
    final result = await _pumpNavigatorHarness(tester, null);
    await tester.tap(find.text("push"));
    await tester.pumpAndSettle();

    expect(result.completed, isTrue);
    expect(result.value, isA<AccessSession>());
    expect(
      (result.value! as AccessSession).status,
      AccessSessionStatus.unlocked,
    );
  });

  testWidgets(
    "shows 'Paiement refusé' for PaymentDeclinedFailure, and 'Réessayer' "
    "pops with the retry-method-selection signal",
    (tester) async {
      final result = await _pumpNavigatorHarness(
        tester,
        const PaymentDeclinedFailure("declined"),
      );
      await tester.tap(find.text("push"));
      await tester.pumpAndSettle();

      expect(find.text("Paiement refusé"), findsOneWidget);

      await tester.tap(find.text("Réessayer"));
      await tester.pumpAndSettle();

      expect(result.completed, isTrue);
      expect(result.value, PaymentRetrySignal.retryMethodSelection);
    },
  );

  testWidgets(
    "shows the unlock-failed-refunded message for UnlockFailedRefundedFailure, "
    "and 'Réessayer' navigates to SCR-013 (re-scan)",
    (tester) async {
      await _pushViaGoRouter(
        tester,
        const UnlockFailedRefundedFailure("unlock failed"),
      );

      expect(
        find.text("Déverrouillage échoué — remboursement en cours"),
        findsOneWidget,
      );

      await tester.tap(find.text("Réessayer"));
      // Not `pumpAndSettle()`: `QrScannerScreen`'s `_ScanTargetFrame` idle
      // pulse is a perpetual `AnimationController.repeat()` loop — same
      // issue `qr_scanner_screen_test.dart` already documents. Bounded
      // pumps instead, long enough for the route transition.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(QrScannerScreen), findsOneWidget);
    },
  );

  testWidgets(
    "shows the generic error message for any other PaymentRepositoryFailure",
    (tester) async {
      await _pushViaGoRouter(tester, const PaymentApiNotConfiguredFailure());

      expect(find.text("Une erreur est survenue"), findsOneWidget);
      expect(find.text("Paiement refusé"), findsNothing);
    },
  );

  testWidgets("'Retour à la carte' navigates to the map", (tester) async {
    final GoRouter router = await _pushViaGoRouter(
      tester,
      const PaymentDeclinedFailure("declined"),
    );

    await tester.tap(find.text("Retour à la carte"));
    await tester.pumpAndSettle();

    expect(find.text("MAP STUB"), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.toString(), "/map");
  });

  testWidgets(
    "the processing message is announced to screen readers via a live "
    "region (US-06.4 finding)",
    (tester) async {
      final delay = Completer<void>();
      addTearDown(() {
        if (!delay.isCompleted) delay.complete();
      });
      final SemanticsHandle handle = tester.ensureSemantics();

      await _pumpNavigatorHarness(tester, null, delay: delay);
      await tester.tap(find.text("push"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final SemanticsNode node = tester.getSemantics(
        find.text("Traitement du paiement..."),
      );
      expect(node.label, "Traitement du paiement...");
      expect(node.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    },
  );

  testWidgets("the failure title is announced via a live region, and the Retry/"
      "back buttons keep their own accessible names (US-06.4 finding — the "
      "live region must be scoped to just the icon+title, not the whole "
      "view, or the buttons would lose their semantics)", (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await _pushViaGoRouter(tester, const PaymentDeclinedFailure("declined"));

    final SemanticsNode titleNode = tester.getSemantics(
      find.text("Paiement refusé"),
    );
    expect(titleNode.label, "Paiement refusé");
    expect(titleNode.flagsCollection.isLiveRegion, isTrue);

    final SemanticsNode retryNode = tester.getSemantics(
      find.widgetWithText(FilledButton, "Réessayer"),
    );
    expect(retryNode.label, "Réessayer");
    expect(retryNode.flagsCollection.isButton, isTrue);

    final SemanticsNode backNode = tester.getSemantics(
      find.widgetWithText(TextButton, "Retour à la carte"),
    );
    expect(backNode.label, "Retour à la carte");
    expect(backNode.flagsCollection.isButton, isTrue);

    handle.dispose();
  });
}
