/// Thrown by [QrCode] when a scanned or manually-entered value fails
/// client-side validation — a distinct type (not a raw `ArgumentError`) so
/// presentation code can catch it specifically and show SCR-013's
/// "invalid QR code" message rather than pattern-matching an error
/// string.
class InvalidQrCodeFailure implements Exception {
  const InvalidQrCodeFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The raw string scanned from a cabin's QR code (or entered via SCR-013's
/// mandatory manual-entry accessibility fallback — both paths produce the
/// same value type, since the backend contract (`AccessSessionCreateRequest
/// .qrCodeScanned`, docs/api/openapi.yaml) doesn't distinguish how the
/// string was obtained).
///
/// Wrapped rather than passed as a bare `String` so a scanned/entered code
/// can't be accidentally interchanged with an unrelated `String` parameter
/// (station ID, cabin ID) elsewhere in this feature's use cases.
///
/// **Validation scope, per ADR-0027**: no QR-payload encoding scheme is
/// documented anywhere in the approved specification — the backend
/// validates a scanned code against live cabin state server-side
/// (docs/architecture/security-architecture.md §5), not the client. This
/// type therefore only rejects what's unambiguously not a plausible code
/// (empty, or implausibly long) — it never attempts to decode a
/// station/cabin identifier from the string.
class QrCode {
  factory QrCode(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const InvalidQrCodeFailure("QR code must not be empty.");
    }
    if (trimmed.length > maxLength) {
      throw const InvalidQrCodeFailure(
        "QR code exceeds the maximum plausible length.",
      );
    }
    return QrCode._(trimmed);
  }

  const QrCode._(this.value);

  /// A judgment call, not a spec-derived limit (ADR-0027) — guards
  /// against a non-QR barcode format or garbage payload being decoded,
  /// not a documented cabin-code length.
  static const int maxLength = 500;

  final String value;

  @override
  bool operator ==(Object other) => other is QrCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
