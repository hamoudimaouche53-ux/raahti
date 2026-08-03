import "dart:async";

import "../../domain/repositories/auth_repository.dart";

/// **Explicitly-opt-in mock adapter** for [AuthRepository] — gated by
/// `AppEnv.useMockAuth` (see that flag's own doc comment). Approves any
/// email/password by default (configurable via [declineAuth], same
/// "configurable success/failure" shape `MockPaymentGatewayAdapter`
/// already established for ADR-0014) — this app never validates a real
/// password against anything, so "wrong credentials" isn't a state this
/// mock can honestly simulate beyond the explicit opt-in flag.
///
/// Stateful (not `const`) like `MockPaymentMethodRepository` — signing in
/// must actually flip [watchCurrentUserId]'s stream so SCR-020 reflects
/// the change without a full app restart. A single instance is shared for
/// the app's lifetime via `auth_providers.dart`'s DI wiring.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.declineAuth = false, String? initialUserId})
    : _userIdController = StreamController<String?>.broadcast(),
      _currentUserId = initialUserId;

  final bool declineAuth;
  final StreamController<String?> _userIdController;
  String? _currentUserId;
  int _nextId = 1;

  @override
  Stream<String?> watchCurrentUserId() async* {
    yield _currentUserId;
    yield* _userIdController.stream;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (declineAuth) {
      throw const AuthRequestFailure(
        "Invalid login credentials (mock, USE_MOCK_AUTH decline mode).",
      );
    }
    _currentUserId = "mock-user-1";
    _userIdController.add(_currentUserId);
  }

  @override
  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (declineAuth) {
      throw const AuthRequestFailure(
        "Could not create account (mock, USE_MOCK_AUTH decline mode).",
      );
    }
    _currentUserId = "mock-user-${_nextId++}";
    _userIdController.add(_currentUserId);
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _currentUserId = null;
    _userIdController.add(null);
  }
}
