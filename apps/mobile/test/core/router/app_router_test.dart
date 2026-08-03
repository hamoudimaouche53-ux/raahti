// Traces to: ADR-0018, ADR-0024. Map's branch is deliberately never
// navigated to here — MapScreen depends on Riverpod providers backed by
// real geolocation/HTTP, exercised separately in
// test/features/map_discovery/**; StatefulShellRoute.indexedStack only
// builds a branch once it is actually navigated to, so testing the
// Slatoki/Emergency/Profile branches never triggers Map's build.
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/app_shell/presentation/screens/splash_screen.dart";
import "package:rahati/features/emergency/presentation/screens/emergency_placeholder_screen.dart";
import "package:rahati/features/profile/presentation/screens/profile_home_screen.dart";
import "package:rahati/features/slatoki/presentation/providers/qibla_providers.dart";
import "package:rahati/features/slatoki/presentation/screens/qibla_full_screen.dart";
import "package:rahati/features/slatoki/presentation/screens/slatoki_screen.dart";
import "package:rahati/features/slatoki/presentation/widgets/qibla_compass.dart";
import "package:rahati/l10n/app_localizations.dart";

Future<GoRouter> _buildRouter(
  WidgetTester tester, {
  String? goTo,
  Locale locale = const Locale("fr"),
}) async {
  // Never touches the real `flutter_compass` platform channel — see the
  // same rationale in slatoki_screen_test.dart's `_wrap`.
  final ProviderContainer container = ProviderContainer(
    overrides: [
      rawCompassEventsProvider.overrideWithValue(const Stream.empty()),
    ],
  );
  addTearDown(container.dispose);
  final GoRouter router = container.read(appRouterProvider);
  if (goTo != null) router.go(goTo);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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
  test("AppRoutePaths exposes every shell destination path", () {
    expect(AppRoutePaths.splash, "/");
    expect(AppRoutePaths.map, "/map");
    expect(AppRoutePaths.slatoki, "/slatoki");
    expect(AppRoutePaths.slatokiQibla, "/slatoki/qibla");
    expect(AppRoutePaths.emergency, "/emergency");
    expect(AppRoutePaths.profile, "/profile");
  });

  test("appRouterProvider builds a usable GoRouter instance", () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final GoRouter router = container.read(appRouterProvider);
    expect(router, isA<GoRouter>());
  });

  testWidgets("navigating the router renders SplashScreen at the root", (
    WidgetTester tester,
  ) async {
    await _buildRouter(tester);

    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets(
    "the shell renders exactly 4 bottom-nav destinations, in fixed order "
    "(US-02.1.1)",
    (WidgetTester tester) async {
      await _buildRouter(tester, goTo: AppRoutePaths.slatoki);

      expect(find.byType(SlatokiScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(4));

      final Finder destinations = find.byType(NavigationDestination);
      final List<double> leftEdges = <double>[
        for (int i = 0; i < 4; i++) tester.getTopLeft(destinations.at(i)).dx,
      ];
      expect(leftEdges, orderedEquals(<double>[...leftEdges]..sort()));
    },
  );

  testWidgets("tapping the Emergency destination shows the placeholder screen, "
      "reachable without visiting the Map branch", (WidgetTester tester) async {
    await _buildRouter(tester, goTo: AppRoutePaths.slatoki);

    await tester.tap(find.text("Urgence"));
    await tester.pumpAndSettle();

    expect(find.byType(EmergencyPlaceholderScreen), findsOneWidget);
    expect(find.text("Mode Urgence"), findsOneWidget);
  });

  testWidgets("tapping the Profile destination shows the real Profile Home screen", (
    WidgetTester tester,
  ) async {
    await _buildRouter(tester, goTo: AppRoutePaths.slatoki);

    await tester.tap(find.text("Profil"));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileHomeScreen), findsOneWidget);
  });

  testWidgets("tapping the compact Qibla Compass card pushes /slatoki/qibla "
      "(US-02.1.2)", (WidgetTester tester) async {
    await _buildRouter(tester, goTo: AppRoutePaths.slatoki);

    await tester.tap(find.byType(QiblaCompass));
    // Not pumpAndSettle(): the compass's "calibrating" pulse animation
    // repeats indefinitely (no compass reading is injected in this test),
    // so nothing would ever settle — same reasoning as
    // nav_shell_screenshot_test.dart's `_settle` helper. Bounded pumps
    // instead, long enough for GoRouter's page-transition animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(QiblaFullScreen), findsOneWidget);
    // SCR-009's "full-screen, minimal chrome" — the shell's bottom nav
    // must NOT still be showing (regression guard: an earlier version
    // nested this route under the Slatoki branch, which kept
    // RahatiNavShell's NavigationBar visible underneath).
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets(
    "destination order stays Map→Slatoki→Emergency→Profile left-to-right "
    "even under an Arabic (RTL) locale (component-library.md §5)",
    (WidgetTester tester) async {
      await _buildRouter(
        tester,
        goTo: AppRoutePaths.slatoki,
        locale: const Locale("ar"),
      );

      final Finder destinations = find.byType(NavigationDestination);
      expect(destinations, findsNWidgets(4));
      final List<double> leftEdges = <double>[
        for (int i = 0; i < 4; i++) tester.getTopLeft(destinations.at(i)).dx,
      ];
      expect(leftEdges, orderedEquals(<double>[...leftEdges]..sort()));
    },
  );
}
