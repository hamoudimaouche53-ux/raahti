import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../features/access_payment/presentation/screens/cabin_availability_screen.dart";
import "../../features/access_payment/presentation/screens/payment_processing_screen.dart";
import "../../features/access_payment/presentation/screens/qr_scanner_screen.dart";
import "../../features/access_payment/presentation/screens/session_complete_screen.dart";
import "../../features/access_payment/presentation/screens/unlock_confirmation_screen.dart";
import "../../features/app_shell/presentation/screens/splash_screen.dart";
import "../../features/app_shell/presentation/widgets/rahati_nav_shell.dart";
import "../../features/emergency/presentation/screens/emergency_placeholder_screen.dart";
import "../../features/map_discovery/presentation/screens/map_screen.dart";
import "../../features/map_discovery/presentation/screens/submit_review_screen.dart";
import "../../features/profile/presentation/screens/favorites_list_screen.dart";
import "../../features/profile/presentation/screens/language_theme_settings_screen.dart";
import "../../features/profile/presentation/screens/my_reviews_screen.dart";
import "../../features/profile/presentation/screens/notification_settings_screen.dart";
import "../../features/profile/presentation/screens/profile_home_screen.dart";
import "../../features/profile/presentation/screens/saved_payment_methods_screen.dart";
import "../../features/profile/presentation/screens/sign_in_sign_up_screen.dart";
import "../../features/profile/presentation/screens/visit_history_screen.dart";
import "../../features/slatoki/presentation/screens/qibla_full_screen.dart";
import "../../features/slatoki/presentation/screens/slatoki_screen.dart";

/// Route path constants. Kept centralized so screens never hard-code a
/// path string inline (single source of truth for navigation targets).
abstract final class AppRoutePaths {
  static const String splash = "/";
  static const String map = "/map";
  static const String slatoki = "/slatoki";
  static const String slatokiQibla = "/slatoki/qibla";
  static const String emergency = "/emergency";
  static const String profile = "/profile";
  static const String profileSignIn = "/profile/sign-in";
  static const String profileVisitHistory = "/profile/visit-history";
  static const String profilePaymentMethods = "/profile/payment-methods";
  static const String profileMyReviews = "/profile/reviews";
  static const String profileFavorites = "/profile/favorites";
  static const String profileNotificationSettings =
      "/profile/notification-settings";
  static const String profileLanguageTheme = "/profile/language-theme";
  static const String submitReview = "/submit-review";
  static const String accessPaymentScan = "/access-payment/scan";
  static const String accessPaymentAvailability =
      "/access-payment/availability";
  static const String accessPaymentProcessing = "/access-payment/processing";
  static const String accessPaymentUnlock = "/access-payment/unlock";
  static const String sessionComplete = "/access-payment/session-complete";
}

/// The root navigator — used as `parentNavigatorKey` for routes that must
/// escape the bottom-nav shell entirely (SCR-009's "full-screen, minimal
/// chrome" requirement; a route nested under a `StatefulShellBranch`
/// without this would still render inside `RahatiNavShell`, keeping the
/// `NavigationBar` visible, which the wireframe explicitly does not want).
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: "root",
);

/// One [GlobalKey] per [StatefulShellBranch] navigator, per GoRouter's
/// `StatefulShellRoute.indexedStack` contract — each branch keeps its own
/// navigation stack and state alive while another branch is shown.
final GlobalKey<NavigatorState> _mapBranchKey = GlobalKey<NavigatorState>(
  debugLabel: "map",
);
final GlobalKey<NavigatorState> _slatokiBranchKey = GlobalKey<NavigatorState>(
  debugLabel: "slatoki",
);
final GlobalKey<NavigatorState> _emergencyBranchKey = GlobalKey<NavigatorState>(
  debugLabel: "emergency",
);
final GlobalKey<NavigatorState> _profileBranchKey = GlobalKey<NavigatorState>(
  debugLabel: "profile",
);

/// GoRouter configuration (ADR-0018, ADR-0024). Splash (SCR-001) is a
/// standalone top-level route; Map/Slatoki/Emergency/Profile live inside a
/// `StatefulShellRoute.indexedStack` — the 4 fixed bottom-nav destinations
/// docs/design/component-library.md §5 mandates. Emergency still renders a
/// zero-logic placeholder screen (ADR-0024) pending EPIC-03 (V1.1); only
/// its branch's screen changes when that epic lands, not this route
/// structure. Profile's placeholder was retired when EPIC-05 landed.
///
/// SCR-009 (Qibla full-screen, US-02.1.2), SCR-013 (QR Scanner, US-04.1),
/// SCR-014 (Cabin Availability Confirmation, US-04.2), SCR-016 (Payment
/// Processing / SCR-018 Payment Failed, US-04.3), SCR-017 (Unlock
/// Confirmation, US-04.4), and SCR-019 (Session Complete, US-04.6) are
/// also top-level routes, not nested under a branch, despite being
/// reached only from Slatoki/Map respectively — every one of these
/// wireframes explicitly calls for "full-screen, minimal chrome"; a route
/// nested under a `StatefulShellBranch` would still render inside
/// `RahatiNavShell`, keeping the bottom `NavigationBar` visible, which
/// none of them want. `parentNavigatorKey: _rootNavigatorKey` is what
/// makes a route escape the shell like this. SCR-014/016/017/019 are
/// sibling routes rather than nested under SCR-013's path — each needs
/// its own `state.extra`-carried payload, not a child of the scan route's
/// navigation stack. SCR-015 (Payment Method Selection) is deliberately
/// **not** a route at all — its wireframe specifies a Modal Bottom Sheet,
/// shown via `showModalBottomSheet` from `PlaceDetailSheet` directly.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutePaths.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.slatokiQibla,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QiblaFullScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.accessPaymentScan,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.accessPaymentAvailability,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            CabinAvailabilityScreen(rawQrValue: state.extra! as String),
      ),
      GoRoute(
        path: AppRoutePaths.accessPaymentProcessing,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final PaymentProcessingArgs args =
              state.extra! as PaymentProcessingArgs;
          return PaymentProcessingScreen(
            accessSessionId: args.accessSessionId,
            paymentMethodId: args.paymentMethodId,
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.accessPaymentUnlock,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final UnlockConfirmationArgs args =
              state.extra! as UnlockConfirmationArgs;
          return UnlockConfirmationScreen(
            cabinCode: args.cabinCode,
            stationName: args.stationName,
            startedAt: args.startedAt,
            amount: args.amount,
            cabinFreedStream: args.cabinFreedStream,
            placeId: args.placeId,
            placeName: args.placeName,
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.sessionComplete,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final SessionCompleteArgs args = state.extra! as SessionCompleteArgs;
          return SessionCompleteScreen(
            amount: args.amount,
            duration: args.duration,
            placeId: args.placeId,
            placeName: args.placeName,
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.submitReview,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final SubmitReviewArgs args = state.extra! as SubmitReviewArgs;
          return SubmitReviewScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutePaths.profileSignIn,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignInSignUpScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profileVisitHistory,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VisitHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profilePaymentMethods,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SavedPaymentMethodsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profileMyReviews,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyReviewsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profileFavorites,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FavoritesListScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profileNotificationSettings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profileLanguageTheme,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LanguageThemeSettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RahatiNavShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _mapBranchKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutePaths.map,
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _slatokiBranchKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutePaths.slatoki,
                builder: (context, state) => const SlatokiScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _emergencyBranchKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutePaths.emergency,
                builder: (context, state) => const EmergencyPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileBranchKey,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutePaths.profile,
                builder: (context, state) => const ProfileHomeScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
