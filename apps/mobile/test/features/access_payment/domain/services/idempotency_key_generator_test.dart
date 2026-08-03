import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/domain/services/idempotency_key_generator.dart";

void main() {
  group("IdempotencyKeyGenerator", () {
    const generator = IdempotencyKeyGenerator();
    final uuidV4Pattern = RegExp(
      r"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$",
    );

    test("generates an RFC 4122 v4-shaped UUID", () {
      final key = generator.generate();
      expect(key, matches(uuidV4Pattern));
    });

    test("generates a fresh value on each call", () {
      final keys = List.generate(100, (_) => generator.generate());
      expect(keys.toSet(), hasLength(100));
    });
  });
}
