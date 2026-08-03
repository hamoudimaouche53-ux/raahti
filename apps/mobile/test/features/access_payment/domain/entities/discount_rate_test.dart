import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/domain/entities/discount_rate.dart";

void main() {
  group("DiscountRate", () {
    test("equality is value-based", () {
      final a = DiscountRate(50);
      final b = DiscountRate(50);
      final c = DiscountRate(25);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test("rejects zero", () {
      expect(() => DiscountRate(0), throwsArgumentError);
    });

    test("rejects a negative percentage", () {
      expect(() => DiscountRate(-10), throwsArgumentError);
    });

    test("rejects a percentage over 100", () {
      expect(() => DiscountRate(101), throwsArgumentError);
    });

    test("accepts 100", () {
      expect(() => DiscountRate(100), returnsNormally);
    });
  });
}
