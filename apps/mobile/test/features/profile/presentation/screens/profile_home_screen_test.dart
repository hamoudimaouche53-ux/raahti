import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/profile/domain/entities/app_user.dart";
import "package:rahati/features/profile/domain/entities/diabetic_verification_status.dart";
import "package:rahati/features/profile/domain/entities/language_preference.dart";
import "package:rahati/features/profile/domain/repositories/auth_repository.dart";
import "package:rahati/features/profile/domain/repositories/user_repository.dart";
import "package:rahati/features/profile/presentation/providers/auth_providers.dart";
import "package:rahati/features/profile/presentation/screens/language_theme_settings_screen.dart";
import "package:rahati/features/profile/presentation/screens/profile_home_screen.dart";
import "package:rahati/features/profile/presentation/screens/sign_in_sign_up_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.userId);
  final String? userId;

  @override
  Stream<String?> watchCurrentUserId() => Stream.value(userId);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeUserRepository implements UserRepository {
  const _FakeUserRepository(this.user);
  final AppUser user;

  @override
  Future<AppUser> getCurrentUser() async => user;
}

const _verifiedUser = AppUser(
  id: "user-1",
  email: "amina.b@example.com",
  phone: null,
  preferredLanguage: LanguagePreference.fr,
  diabeticVerificationStatus: DiabeticVerificationStatus.verified,
);

Future<GoRouter> _pushViaGoRouter(
  WidgetTester tester, {
  String? userId,
  AppUser? user,
  Locale locale = const Locale("fr"),
}) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.profile,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.profile,
        builder: (context, state) => const ProfileHomeScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profileSignIn,
        builder: (context, state) => const SignInSignUpScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.profileLanguageTheme,
        builder: (context, state) => const LanguageThemeSettingsScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(userId),
        ),
        if (user != null)
          userRepositoryProvider.overrideWithValue(_FakeUserRepository(user)),
      ],
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
  testWidgets(
    "guest state shows 'Compte invité' and a 'Se connecter' button",
    (tester) async {
      await _pushViaGoRouter(tester, userId: null);

      expect(find.text("Compte invité"), findsOneWidget);
      expect(find.text("Se connecter"), findsWidgets);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    },
  );

  testWidgets(
    "tapping a locked item as a guest shows the 'Connexion requise' "
    "Snackbar without navigating",
    (tester) async {
      await _pushViaGoRouter(tester, userId: null);

      await tester.tap(find.text("Historique des visites"));
      await tester.pump();

      expect(find.text("Connexion requise"), findsOneWidget);
    },
  );

  testWidgets(
    "tapping 'Se connecter' pushes SCR-030 (SignInSignUpScreen)",
    (tester) async {
      await _pushViaGoRouter(tester, userId: null);

      await tester.tap(find.text("Se connecter"));
      await tester.pumpAndSettle();

      expect(find.byType(SignInSignUpScreen), findsOneWidget);
    },
  );

  testWidgets(
    "registered state shows the account email and the verified-diabetic "
    "badge, no 'Se connecter' button",
    (tester) async {
      await _pushViaGoRouter(
        tester,
        userId: "user-1",
        user: _verifiedUser,
      );

      expect(find.text("amina.b@example.com"), findsOneWidget);
      expect(find.text("Diabétique vérifié"), findsOneWidget);
      expect(find.text("Se connecter"), findsNothing);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    },
  );

  testWidgets(
    "'Statut diabétique vérifié' always shows the coming-soon Snackbar, "
    "even when registered (US-05.3 deferred to V1.1)",
    (tester) async {
      await _pushViaGoRouter(tester, userId: "user-1", user: _verifiedUser);

      await tester.tap(find.text("Statut diabétique vérifié"));
      await tester.pump();

      expect(find.text("Bientôt disponible"), findsOneWidget);
    },
  );

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pushViaGoRouter(tester, userId: null, locale: const Locale("ar"));

    expect(find.text("حساب زائر"), findsOneWidget);
  });

  testWidgets(
    "'Langue et thème' is never locked and navigates to SCR-029, "
    "even as a guest (device-level preference, not account-bound)",
    (tester) async {
      await _pushViaGoRouter(tester, userId: null);

      await tester.ensureVisible(find.text("Langue et thème"));
      await tester.pump();
      await tester.tap(find.text("Langue et thème"));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageThemeSettingsScreen), findsOneWidget);
      expect(find.text("Connexion requise"), findsNothing);
    },
  );

  testWidgets(
    "'Langue et thème' navigates to SCR-029 when registered too",
    (tester) async {
      await _pushViaGoRouter(tester, userId: "user-1", user: _verifiedUser);

      await tester.ensureVisible(find.text("Langue et thème"));
      await tester.pump();
      await tester.tap(find.text("Langue et thème"));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageThemeSettingsScreen), findsOneWidget);
    },
  );

  testWidgets(
    "the verified-diabetic list-row badge icon exposes an accessible "
    "label, not just color/shape (US-06.4)",
    (tester) async {
      await _pushViaGoRouter(tester, userId: "user-1", user: _verifiedUser);

      final Iterable<Icon> checkIcons = tester.widgetList<Icon>(
        find.byIcon(Icons.check_circle),
      );
      expect(
        checkIcons.any((icon) => icon.semanticLabel == "Diabétique vérifié"),
        isTrue,
        reason:
            "expected at least one check_circle icon (the list-row "
            "trailing badge) to carry semanticLabel 'Diabétique vérifié' — "
            "an unlabeled Icon is excluded from the semantics tree "
            "entirely",
      );
    },
  );

  testWidgets(
    "a sign-in-gated locked item announces 'Connexion requise' as a "
    "semantics hint before activation, not only via the post-tap "
    "Snackbar (US-06.4)",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pushViaGoRouter(tester, userId: null);

      final SemanticsNode node = tester.getSemantics(
        find.text("Historique des visites"),
      );
      expect(node.hint, "Connexion requise");
      handle.dispose();
    },
  );

  testWidgets(
    "the always-locked 'coming soon' items (diabetic status, "
    "notifications) hint 'Bientôt disponible', not the misleading "
    "sign-in-required hint, even when registered (US-06.4)",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pushViaGoRouter(tester, userId: "user-1", user: _verifiedUser);

      final SemanticsNode diabeticNode = tester.getSemantics(
        find.text("Statut diabétique vérifié"),
      );
      expect(diabeticNode.hint, "Bientôt disponible");

      final SemanticsNode notificationsNode = tester.getSemantics(
        find.text("Notifications"),
      );
      expect(notificationsNode.hint, "Bientôt disponible");
      handle.dispose();
    },
  );
}
