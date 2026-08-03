import "dart:math";

/// Generates the `Idempotency-Key` header value required by every
/// state-changing Access & Payment endpoint (docs/api/api-architecture.md
/// §8 — the backend deduplicates on `(user, key)` for a rolling 24h
/// window, directly mitigating Risk R-11/R-12's double-charge/duplicate-
/// session concern).
///
/// Deliberately hand-rolled (a UUID v4, RFC 4122 §4.4) rather than adding
/// a `uuid` package dependency for one call site — `Random.secure()` is
/// cryptographically strong and sufficient for this purpose.
///
/// One key must be generated **per user-initiated attempt**, not per HTTP
/// call — a network-failure retry of the *same* attempt reuses the same
/// key (so the backend dedupes it); a genuinely new attempt (e.g. picking
/// a different payment method after a decline) gets a fresh key.
class IdempotencyKeyGenerator {
  const IdempotencyKeyGenerator();

  String generate() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // Per RFC 4122 §4.4: set version (4) and variant (10) bits.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, "0"))
        .join();

    return "${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}";
  }
}
