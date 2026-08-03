import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/profile/domain/entities/diabetic_verification_status.dart";

void main() {
  group("DiabeticVerificationStatus.fromWireValue", () {
    test("maps all four wire values", () {
      expect(
        DiabeticVerificationStatus.fromWireValue("none"),
        DiabeticVerificationStatus.none,
      );
      expect(
        DiabeticVerificationStatus.fromWireValue("pending"),
        DiabeticVerificationStatus.pending,
      );
      expect(
        DiabeticVerificationStatus.fromWireValue("verified"),
        DiabeticVerificationStatus.verified,
      );
      expect(
        DiabeticVerificationStatus.fromWireValue("rejected"),
        DiabeticVerificationStatus.rejected,
      );
    });

    test("falls back to none for an unrecognized value", () {
      expect(
        DiabeticVerificationStatus.fromWireValue("bogus"),
        DiabeticVerificationStatus.none,
      );
    });
  });
}
