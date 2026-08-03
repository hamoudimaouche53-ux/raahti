import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/access_payment/domain/entities/access_session.dart";
import "package:rahati/features/access_payment/domain/entities/access_session_status.dart";
import "package:rahati/features/access_payment/domain/entities/qr_code.dart";
import "package:rahati/features/access_payment/domain/repositories/access_session_repository.dart";
import "package:rahati/features/access_payment/presentation/providers/access_session_providers.dart";
import "package:rahati/features/access_payment/presentation/screens/cabin_availability_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

class _FakeAccessSessionRepository implements AccessSessionRepository {
  _FakeAccessSessionRepository({this.failure, this.delay});

  final AccessSessionRepositoryFailure? failure;

  /// When set, [initiateAccessSession] doesn't resolve until this
  /// [Completer] completes — used to freeze the screen in its `checking`
  /// state so it can be asserted on.
  final Completer<void>? delay;

  static final AccessSession _session = AccessSession(
    id: "session-1",
    cabinId: "cabin-1",
    status: AccessSessionStatus.initiated,
    startedAt: DateTime(2026),
    unlockedAt: null,
  );

  @override
  Future<AccessSession> initiateAccessSession({
    required QrCode qrCodeScanned,
    required String idempotencyKey,
  }) async {
    final Completer<void>? d = delay;
    if (d != null) await d.future;
    final AccessSessionRepositoryFailure? f = failure;
    if (f != null) throw f;
    return _session;
  }

  @override
  Future<AccessSession> getAccessSession(String accessSessionId) {
    throw UnimplementedError();
  }
}

/// Captures the eventual pop result of a pushed [CabinAvailabilityScreen]
/// without forcing the caller to `pumpAndSettle` — some tests need to
/// inspect an intermediate (`checking`/brief-success) frame instead.
class _PushResult {
  AccessSession? value;
  bool completed = false;
}

/// Pumps [CabinAvailabilityScreen] behind an unpressed "push" button, via
/// a plain [Navigator] (not go_router) — sufficient for the
/// `checking`/`available` states, which only ever call
/// `Navigator.of(context).pop`. Callers tap "push" themselves so they
/// control exactly how much time is pumped afterward.
Future<_PushResult> _pumpNavigatorHarness(
  WidgetTester tester,
  AccessSessionRepositoryFailure? failure, {
  Completer<void>? delay,
}) async {
  final _PushResult result = _PushResult();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accessSessionRepositoryProvider.overrideWithValue(
          _FakeAccessSessionRepository(failure: failure, delay: delay),
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
              result.value = await Navigator.of(context).push<AccessSession>(
                MaterialPageRoute(
                  builder: (_) => const CabinAvailabilityScreen(
                    rawQrValue: "RAHETI-STATION-1-CABIN-2",
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

/// Pumps [CabinAvailabilityScreen] via a minimal [GoRouter] — needed for
/// the `unavailable`/generic-error states, whose "Retour à la carte"
/// button calls `context.go(AppRoutePaths.map)`.
Future<GoRouter> _pushViaGoRouter(
  WidgetTester tester,
  AccessSessionRepositoryFailure? failure,
) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.accessPaymentAvailability,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.accessPaymentAvailability,
        builder: (context, state) => const CabinAvailabilityScreen(
          rawQrValue: "RAHETI-STATION-1-CABIN-2",
        ),
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
        accessSessionRepositoryProvider.overrideWithValue(
          _FakeAccessSessionRepository(failure: failure),
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
  testWidgets("shows the checking message and a progress indicator while "
      "the request is in flight", (tester) async {
    final delay = Completer<void>();
    addTearDown(() {
      if (!delay.isCompleted) delay.complete();
    });

    await _pumpNavigatorHarness(tester, null, delay: delay);
    await tester.tap(find.text("push"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text("Vérification de la disponibilité..."), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    "shows the available success message, then pops with the created "
    "AccessSession",
    (tester) async {
      final _PushResult result = await _pumpNavigatorHarness(tester, null);
      await tester.tap(find.text("push"));
      // `pumpAndSettle` alone won't advance past this: the 700ms
      // success-flash delay is a bare `Future.delayed` Timer, not tied to
      // an animation, so it never marks a frame as "scheduled" for
      // `pumpAndSettle` to wait on.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pumpAndSettle();

      expect(result.completed, isTrue);
      expect(result.value?.id, "session-1");
    },
  );

  testWidgets(
    "flashes 'Cabine disponible' before the auto-advance pop",
    (tester) async {
      await _pumpNavigatorHarness(tester, null);
      await tester.tap(find.text("push"));
      // Enough time for the fake repository's Future to resolve, not
      // enough for the 700ms success-flash delay to elapse.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text("Cabine disponible"), findsOneWidget);

      // Flush the remaining success-flash Timer + pop so the test binding
      // doesn't flag a pending Timer at teardown.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    "shows the unavailable message and a working 'Retour à la carte' "
    "button for CabinUnavailableFailure (409)",
    (tester) async {
      final GoRouter router = await _pushViaGoRouter(
        tester,
        const CabinUnavailableFailure(),
      );

      expect(
        find.text("Cette cabine n'est plus disponible."),
        findsOneWidget,
      );
      expect(find.text("Retour à la carte"), findsOneWidget);

      await tester.tap(find.text("Retour à la carte"));
      await tester.pumpAndSettle();

      expect(find.text("MAP STUB"), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.toString(), "/map");
    },
  );

  testWidgets(
    "shows the generic error message (not the cabin-unavailable one) for "
    "any other repository failure",
    (tester) async {
      await _pushViaGoRouter(
        tester,
        const AccessPaymentApiNotConfiguredFailure(),
      );

      expect(
        find.text("Impossible de démarrer la session. Veuillez réessayer."),
        findsOneWidget,
      );
      expect(
        find.text("Cette cabine n'est plus disponible."),
        findsNothing,
      );
      expect(find.text("Retour à la carte"), findsOneWidget);
    },
  );
}
