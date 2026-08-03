import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/profile/data/repositories/mock_user_repository.dart";
import "package:rahati/features/profile/domain/entities/diabetic_verification_status.dart";

void main() {
  test("MockUserRepository returns a fixed, verified-diabetic profile", () async {
    const repo = MockUserRepository();
    final user = await repo.getCurrentUser();
    expect(user.email, isNotNull);
    expect(
      user.diabeticVerificationStatus,
      DiabeticVerificationStatus.verified,
    );
  });
}
