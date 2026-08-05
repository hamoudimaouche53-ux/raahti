import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/access_payment/presentation/screens/cabin_availability_screen.dart";
import "package:rahati/features/access_payment/presentation/screens/qr_scanner_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

// The device camera is unavailable in `flutter test` (no platform channel
// implementation registered) — `mobile_scanner` handles this gracefully
// internally (routes it through its own error state rather than throwing),
// which is what makes this screen testable at all here. Full live-camera
// behavior (scanning state, a real "recognized" flash) can only be
// verified on a physical device — same limitation this log has already
// applied to Qibla's magnetometer/GPS (ADR-0025) — so these tests cover
// what doesn't depend on live hardware: the always-present chrome, the
// manual-entry accessibility fallback, and validation feedback.
// `pumpAndSettle()` never returns on this screen — `_ScanTargetFrame`'s
// idle pulse is a perpetual `AnimationController.repeat()` loop, the same
// category of issue this log has hit before (Qibla's calibrating pulse,
// Map's GPS stream) and solved the same way: bounded `pump()` calls
// instead.
Future<void> _settle(WidgetTester tester, {int times = 5}) async {
  for (int i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpScreen(WidgetTester tester, {String locale = "fr"}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: RahatiTheme.light,
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const QrScannerScreen(),
      ),
    ),
  );
  await tester.pump();
}

/// Wraps [QrScannerScreen] in a minimal [GoRouter] (just the scan +
/// availability routes) — needed only by the navigation test below, which
/// exercises `context.push(AppRoutePaths.accessPaymentAvailability)`; every
/// other test in this file uses the plain `_pumpScreen` helper since
/// nothing else in this screen touches go_router.
Future<void> _pumpScreenWithRouter(WidgetTester tester) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.accessPaymentScan,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.accessPaymentScan,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.accessPaymentAvailability,
        builder: (context, state) =>
            CabinAvailabilityScreen(rawQrValue: state.extra! as String),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
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
}

void main() {
  testWidgets("smoke: builds without throwing", (tester) async {
    await _pumpScreen(tester);

    expect(find.byType(QrScannerScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "shows the instruction strip and the manual-entry fallback button",
    (tester) async {
      await _pumpScreen(tester);

      expect(find.text("Scannez le QR code sur la cabine."), findsOneWidget);
      expect(find.text("Saisir le code manuellement"), findsOneWidget);
    },
  );

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pumpScreen(tester, locale: "ar");

    expect(tester.takeException(), isNull);
    expect(find.text("امسح رمز QR الموجود على الكابينة."), findsOneWidget);
  });

  testWidgets("the manual-entry dialog opens on tap and can be cancelled", (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.tap(find.text("Saisir le code manuellement"));
    await _settle(tester);
    expect(find.text("Saisir le code"), findsOneWidget);

    await tester.tap(find.text("Annuler"));
    await _settle(tester);
    expect(find.text("Saisir le code"), findsNothing);
  });

  testWidgets(
    "submitting an empty manual code shows the invalid-code message and "
    "keeps the user on SCR-013",
    (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text("Saisir le code manuellement"));
      await _settle(tester);
      await tester.tap(find.text("Valider"));
      await _settle(tester);

      expect(
        find.text("Code QR invalide. Veuillez réessayer."),
        findsOneWidget,
      );
      expect(find.byType(QrScannerScreen), findsOneWidget);
    },
  );

  testWidgets(
    "submitting a valid manual code pushes SCR-014 "
    "(CabinAvailabilityScreen)",
    (tester) async {
      await _pumpScreenWithRouter(tester);

      await tester.tap(find.text("Saisir le code manuellement"));
      await _settle(tester);
      await tester.enterText(
        find.byType(TextField),
        "RAHETI-STATION-1-CABIN-2",
      );
      await tester.tap(find.text("Valider"));
      await _settle(tester);

      expect(find.byType(CabinAvailabilityScreen), findsOneWidget);
    },
  );

  group(
    "overlay elements have a guaranteed-contrast scrim backdrop, not a "
    "bare color against the unpredictable live camera feed (US-06.4 "
    "finding F4)",
    () {
      testWidgets(
        "the AppBar back button is scrim-backed (previously unguarded)",
        (tester) async {
          await _pumpScreen(tester);

          final BackButton backButton = tester.widget<BackButton>(
            find.byType(BackButton),
          );
          expect(backButton.color, Colors.white);

          final DecoratedBox scrim = tester.widget<DecoratedBox>(
            find
                .ancestor(
                  of: find.byType(BackButton),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          final BoxDecoration decoration =
              scrim.decoration as BoxDecoration;
          expect(decoration.color, const Color(0x99000000));
          expect(decoration.shape, BoxShape.circle);
        },
      );

      testWidgets(
        "the manual-entry button is scrim-backed (previously bare against "
        "the camera feed)",
        (tester) async {
          await _pumpScreen(tester);

          final Container scrim = tester.widget<Container>(
            find
                .ancestor(
                  of: find.widgetWithText(
                    TextButton,
                    "Saisir le code manuellement",
                  ),
                  matching: find.byType(Container),
                )
                .first,
          );
          final BoxDecoration decoration =
              scrim.decoration! as BoxDecoration;
          expect(decoration.color, const Color(0x99000000));
        },
      );
    },
  );
}
