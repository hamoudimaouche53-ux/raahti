import "../entities/app_user.dart";

sealed class UserRepositoryFailure implements Exception {
  const UserRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserApiNotConfiguredFailure extends UserRepositoryFailure {
  const UserApiNotConfiguredFailure()
    : super("No backend API is configured for this build.");
}

class UserRequestFailure extends UserRepositoryFailure {
  const UserRequestFailure(super.message);
}

/// Repository port for `GET /users/me` (SCR-020's account summary card) —
/// see [AuthRepository]'s doc comment for why this is a separate port
/// from Supabase Auth's own session state.
abstract interface class UserRepository {
  Future<AppUser> getCurrentUser();
}
