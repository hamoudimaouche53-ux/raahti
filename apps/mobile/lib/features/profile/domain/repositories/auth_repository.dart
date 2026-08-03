import "../entities/app_user.dart";

sealed class AuthRepositoryFailure implements Exception {
  const AuthRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Neither a real Supabase project ([AppEnv.isSupabaseConfigured]) nor the
/// explicit mock opt-in ([AppEnv.useMockAuth]) is configured for this
/// build — mirrors `_UnavailableCabinRealtimeRepository`'s three-way
/// mock/real/unavailable swap pattern (Feature 17), not the
/// two-way mock/REST pattern most other repositories use, because
/// Supabase Auth (unlike this app's own backend) can be genuinely wired
/// and load-bearing independent of ADR-0016's still-open backend-hosting
/// decision — there is a real "not configured yet" state distinct from
/// "backend not deployed yet."
class AuthNotConfiguredFailure extends AuthRepositoryFailure {
  const AuthNotConfiguredFailure()
    : super("No Supabase project is configured for this build.");
}

/// Wraps Supabase Auth's own `AuthException` (invalid credentials, email
/// already registered, weak password, etc.) — this app's UI layer (SCR-030)
/// only ever sees this domain-level failure, never a `supabase_flutter`
/// type directly, same "no vendor type escapes the data layer" discipline
/// `PaymentGateway`'s result types already apply to the payment provider.
class AuthRequestFailure extends AuthRepositoryFailure {
  const AuthRequestFailure(super.message);
}

/// Repository port for account authentication (SCR-030, US-05.1) —
/// Supabase Auth per ADR-0009, email + password for this pass (OTP/phone
/// deferred, see Feature 19's Blockers/Assumptions: phone OTP needs an SMS
/// provider selected first, an infra decision this mobile-app pass
/// doesn't make, same reasoning ADR-0014 applied to payment providers).
///
/// Deliberately separate from [UserRepository] — this port only knows
/// "is someone authenticated, and as whom" (a Supabase Auth session);
/// [UserRepository] owns the RAHATI-specific profile row
/// (`GET /users/me`) that session unlocks. Conflating the two would mean
/// every auth state change also required a profile fetch to succeed,
/// which isn't true (a freshly-registered account has an auth session
/// before its profile is fully provisioned server-side).
abstract interface class AuthRepository {
  /// Emits the current Supabase Auth user id (`null` = signed out/guest)
  /// on every auth state change (sign in, sign up, sign out, token
  /// refresh) — the single source of truth `currentUserIdProvider`
  /// exposes to the rest of the app. A bare `String?` id, not an
  /// [AppUser] — resolving the full RAHATI profile is [UserRepository]'s
  /// job, kept separate per this class's own doc comment.
  Stream<String?> watchCurrentUserId();

  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUpWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
