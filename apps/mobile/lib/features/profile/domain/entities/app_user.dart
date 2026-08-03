import "diabetic_verification_status.dart";
import "language_preference.dart";

/// A signed-in account — `User` in docs/api/openapi.yaml,
/// `USER_ACCOUNT` in docs/erd/erd.md §3.6.
///
/// Named `AppUser`, not `User` — `package:supabase_flutter` already
/// exports a `User` type (the raw Supabase Auth user record), and this
/// app's own domain entity is a distinct, narrower shape (only what
/// `GET /users/me` actually returns), so reusing the name would either
/// collide on import or silently conflate "Supabase Auth session" with
/// "RAHATI account profile" — two different concerns even though one
/// backs the other (see `AuthRepository`'s doc comment).
///
/// No `AppUser` instance exists for a guest — per FR-USR-01/ERD §3.6's own
/// constraint ("guest usage requires no row at all"), the guest state is
/// represented as `null` wherever an `AppUser?` is expected
/// (`currentUserProvider`), never a placeholder/empty instance.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.preferredLanguage,
    required this.diabeticVerificationStatus,
  });

  final String id;
  final String? email;
  final String? phone;
  final LanguagePreference preferredLanguage;
  final DiabeticVerificationStatus diabeticVerificationStatus;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.email == email &&
      other.phone == phone &&
      other.preferredLanguage == preferredLanguage &&
      other.diabeticVerificationStatus == diabeticVerificationStatus;

  @override
  int get hashCode => Object.hash(
    id,
    email,
    phone,
    preferredLanguage,
    diabeticVerificationStatus,
  );
}
