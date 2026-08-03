import "../../domain/entities/app_user.dart";
import "../../domain/entities/diabetic_verification_status.dart";
import "../../domain/entities/language_preference.dart";
import "../../domain/repositories/user_repository.dart";

/// **Explicitly-opt-in mock adapter** for [UserRepository] — gated by
/// `AppEnv.useMockAuth` (see that flag's own doc comment). Returns a
/// fixed, clearly-fabricated profile — SCR-020's account summary card
/// ("Amina B.", verified-diabetic badge) matches the wireframe's own
/// ASCII mockup, same "demo the actual documented state" precedent
/// `MockPlaceDetailRepository` established.
class MockUserRepository implements UserRepository {
  const MockUserRepository();

  @override
  Future<AppUser> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const AppUser(
      id: "mock-user-1",
      email: "amina.b@example.com",
      phone: null,
      preferredLanguage: LanguagePreference.fr,
      diabeticVerificationStatus: DiabeticVerificationStatus.verified,
    );
  }
}
