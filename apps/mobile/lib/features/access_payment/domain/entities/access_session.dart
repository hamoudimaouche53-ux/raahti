import "access_session_status.dart";

/// The aggregate root of the Access & Payment bounded context
/// (docs/architecture/domain-model.md §6) — owns the QR-scan-to-unlock
/// journey.
///
/// Deliberately narrower than the domain model's conceptual description
/// and the ERD's `access_session` table — this class mirrors exactly what
/// `AccessSession` in docs/api/openapi.yaml returns from
/// `POST /access-sessions` and `GET /access-sessions/{id}` (verified
/// against the schema directly, not the summarized research pass):
/// `id`, `cabinId`, `status`, `startedAt`, `unlockedAt`. No more.
///
/// Three fields the backend/ERD model are deliberately **not** here:
/// - `qrCodeScanned` / `userId` — the ERD's `access_session` table has
///   both, but neither is in the OpenAPI response schema; the app already
///   knows the QR code it just scanned (it sent it), so there's nothing
///   to round-trip, and no Identity/auth module exists yet to supply a
///   user ID.
/// - `transaction` — the OpenAPI contract models this relationship in the
///   *opposite* direction from the ERD's FK: `Transaction` embeds
///   `AccessSession` (its own schema has an `accessSession` field), this
///   class never embeds a `Transaction`. `POST
///   /access-sessions/{id}/payments` returns a `Transaction`, not an
///   `AccessSession` — this class is what that endpoint's response nests,
///   not the reverse.
///
/// No `closedAt` field either, even though docs/erd/erd.md §3.10 has
/// one — the OpenAPI response schema doesn't expose it (a documented gap
/// flagged during the EPIC-04 architecture review). This app relies on
/// [status] transitions plus the Realtime broadcast (FR-PAY-05) rather
/// than modeling a field the wire contract doesn't actually return; add
/// it back only if a future contract version exposes it.
class AccessSession {
  const AccessSession({
    required this.id,
    required this.cabinId,
    required this.status,
    required this.startedAt,
    required this.unlockedAt,
  });

  final String id;
  final String cabinId;
  final AccessSessionStatus status;
  final DateTime startedAt;

  /// `null` until [status] reaches [AccessSessionStatus.unlocked].
  final DateTime? unlockedAt;

  @override
  bool operator ==(Object other) =>
      other is AccessSession &&
      other.id == id &&
      other.cabinId == cabinId &&
      other.status == status &&
      other.startedAt == startedAt &&
      other.unlockedAt == unlockedAt;

  @override
  int get hashCode => Object.hash(id, cabinId, status, startedAt, unlockedAt);
}
