/// Mirrors `AccessSession.status` in docs/api/openapi.yaml and
/// docs/erd/erd.md §3.10 exactly — six values, no more, no fewer.
///
/// Invariant (docs/architecture/domain-model.md §6): [unlocked] may only be
/// reached from [initiated] directly (free cabin) or via [paymentPending]
/// after a captured payment (paid cabin) — never before payment for a paid
/// cabin. This type only models the values; the transition itself is
/// enforced by the backend (this app has no local state machine to
/// duplicate that authority).
enum AccessSessionStatus {
  initiated,
  paymentPending,
  unlocked,
  inUse,
  completed,
  cancelled,
}
