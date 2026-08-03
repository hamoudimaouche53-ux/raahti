import "package:supabase_flutter/supabase_flutter.dart";

import "../../domain/repositories/auth_repository.dart";

/// [AuthRepository] implementation backed by Supabase Auth (ADR-0009) —
/// the production default once [AppEnv.isSupabaseConfigured] is `true`.
/// Email + password only for this pass (see [AuthRepository]'s own doc
/// comment for why OTP/phone are deferred).
class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<String?> watchCurrentUserId() async* {
    // Seed with whatever session already exists (e.g. a token restored
    // from the previous app launch) — `onAuthStateChange` alone only
    // emits on the *next* transition, not the current state.
    yield _client.auth.currentSession?.user.id;
    yield* _client.auth.onAuthStateChange.map(
      (state) => state.session?.user.id,
    );
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthRequestFailure(e.message);
    }
  }

  @override
  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthRequestFailure(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthRequestFailure(e.message);
    }
  }
}
