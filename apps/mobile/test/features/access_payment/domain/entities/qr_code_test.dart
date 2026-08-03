import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/domain/entities/qr_code.dart";

void main() {
  group("QrCode", () {
    test("equality is value-based", () {
      final a = QrCode("RAHETI-STATION-1-CABIN-2");
      final b = QrCode("RAHETI-STATION-1-CABIN-2");
      final c = QrCode("RAHETI-STATION-1-CABIN-3");
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test("trims surrounding whitespace (manual-entry fallback)", () {
      final qr = QrCode("  RAHETI-STATION-1-CABIN-2  ");
      expect(qr.value, "RAHETI-STATION-1-CABIN-2");
    });

    test("rejects an empty value", () {
      expect(() => QrCode(""), throwsA(isA<InvalidQrCodeFailure>()));
    });

    test("rejects a whitespace-only value", () {
      expect(() => QrCode("   "), throwsA(isA<InvalidQrCodeFailure>()));
    });

    test("accepts a value at the maximum plausible length", () {
      final value = "A" * QrCode.maxLength;
      expect(() => QrCode(value), returnsNormally);
    });

    test("rejects a value beyond the maximum plausible length", () {
      final value = "A" * (QrCode.maxLength + 1);
      expect(() => QrCode(value), throwsA(isA<InvalidQrCodeFailure>()));
    });
  });
}
