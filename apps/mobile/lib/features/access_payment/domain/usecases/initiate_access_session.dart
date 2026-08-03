import "../entities/access_session.dart";
import "../entities/qr_code.dart";
import "../repositories/access_session_repository.dart";
import "../services/idempotency_key_generator.dart";

/// Application-layer use case for FR-PAY-01/02 (US-04.1) — validates the
/// scanned/entered payload, attaches a fresh `Idempotency-Key`, and calls
/// [AccessSessionRepository] only once both have succeeded.
///
/// [QrCode]'s constructor is the validation step — it throws
/// [InvalidQrCodeFailure] for an empty or implausibly long value, which
/// this use case deliberately lets propagate *before* generating an
/// idempotency key or touching the repository, per the story's explicit
/// "validate before any network request" requirement.
class InitiateAccessSession {
  const InitiateAccessSession(
    this._repository, {
    this._idempotencyKeyGenerator = const IdempotencyKeyGenerator(),
  });

  final AccessSessionRepository _repository;
  final IdempotencyKeyGenerator _idempotencyKeyGenerator;

  /// [rawValue] is the raw scanned or manually-entered string — validated
  /// here via [QrCode], not by the caller.
  Future<AccessSession> call({required String rawValue}) {
    final QrCode qrCode = QrCode(rawValue);
    final String idempotencyKey = _idempotencyKeyGenerator.generate();
    return _repository.initiateAccessSession(
      qrCodeScanned: qrCode,
      idempotencyKey: idempotencyKey,
    );
  }
}
