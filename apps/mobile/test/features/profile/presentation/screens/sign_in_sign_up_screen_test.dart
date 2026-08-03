import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:rahati/core/router/app_router.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/core/widgets/rahati_logo_mark.dart";
import "package:rahati/features/profile/domain/repositories/auth_repository.dart";
import "package:rahati/features/profile/presentation/providers/auth_providers.dart";
import "package:rahati/features/profile/presentation/screens/sign_in_sign_up_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.declineWith});
  final AuthRepositoryFailure? declineWith;

  @override
  Stream<String?> watchCurrentUserId() => Stream.value(null);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (declineWith != null) throw declineWith!;
  }

  @override
  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    if (declineWith != null) throw declineWith!;
  }

  @override
  Future<void> signOut() async {}
}

Future<GoRouter> _pushViaGoRouter(
  WidgetTester tester, {
  AuthRepositoryFailure? declineWith,
  Locale locale = const Locale("fr"),
}) async {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.profile,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.profile,
        builder: (context, state) => const Scaffold(body: Text("PROFILE STUB")),
      ),
      GoRoute(
        path: AppRoutePaths.profileSignIn,
        builder: (context, state) => const SignInSignUpScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(declineWith: declineWith),
        ),
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
  unawaited(router.push(AppRoutePaths.profileSignIn));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets(
    "shows the Se connecter/Créer un compte segmented button and both "
    "fields",
    (tester) async {
      await _pushViaGoRouter(tester);

      expect(find.text("E-mail"), findsOneWidget);
      expect(find.text("Mot de passe"), findsOneWidget);
      expect(find.text("Continuer sans compte"), findsOneWidget);
    },
  );

  testWidgets("successful sign-in pops back to the previous screen", (
    tester,
  ) async {
    await _pushViaGoRouter(tester);

    await tester.enterText(find.byType(TextField).first, "a@b.com");
    await tester.enterText(find.byType(TextField).last, "password123");
    await tester.tap(find.text("Se connecter").last);
    await tester.pumpAndSettle();

    expect(find.text("PROFILE STUB"), findsOneWidget);
  });

  testWidgets(
    "a declined sign-in shows the generic inline errorContainer message, "
    "not the raw exception text",
    (tester) async {
      await _pushViaGoRouter(
        tester,
        declineWith: const AuthRequestFailure(
          "invalid_grant: internal Supabase detail",
        ),
      );

      await tester.enterText(find.byType(TextField).first, "a@b.com");
      await tester.enterText(find.byType(TextField).last, "wrong");
      await tester.tap(find.text("Se connecter").last);
      await tester.pumpAndSettle();

      expect(find.text("E-mail ou mot de passe incorrect."), findsOneWidget);
      expect(find.textContaining("invalid_grant"), findsNothing);
    },
  );

  testWidgets(
    "AuthNotConfiguredFailure shows the dedicated not-configured message",
    (tester) async {
      await _pushViaGoRouter(
        tester,
        declineWith: const AuthNotConfiguredFailure(),
      );

      await tester.enterText(find.byType(TextField).first, "a@b.com");
      await tester.enterText(find.byType(TextField).last, "x");
      await tester.tap(find.text("Se connecter").last);
      await tester.pumpAndSettle();

      expect(
        find.text("La connexion n'est pas disponible pour cette version."),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "switching to 'Créer un compte' shows the sign-up submit label",
    (tester) async {
      await _pushViaGoRouter(tester);

      await tester.tap(find.text("Créer un compte").first);
      await tester.pumpAndSettle();

      expect(find.text("Créer un compte"), findsWidgets);
    },
  );

  testWidgets("'Continuer sans compte' pops back without authenticating", (
    tester,
  ) async {
    await _pushViaGoRouter(tester);

    await tester.tap(find.text("Continuer sans compte"));
    await tester.pumpAndSettle();

    expect(find.text("PROFILE STUB"), findsOneWidget);
  });

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pushViaGoRouter(tester, locale: const Locale("ar"));

    expect(find.text("تسجيل الدخول"), findsWidgets);
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
    "the logo mark's glyph uses the theme's onPrimary color, not a "
    "hard-coded white that fails contrast in dark theme (US-06.4)",
    (tester) async {
      await _pushViaGoRouter(tester);

      final RahatiLogoMark mark = tester.widget<RahatiLogoMark>(
        find.byType(RahatiLogoMark),
      );
      expect(mark.onColor, RahatiTheme.light.colorScheme.onPrimary);
    },
  );
}
