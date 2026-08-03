# ADR-0026: Unlock-Wait Timeout & Stale-Session Handling — Temporary Client-Side Policy Pending Backend/IoT SLA

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-01 |
| **Deciders** | Engineering team (per EPIC-04 pre-implementation architecture review) |
| **Phase** | Phase 3 — Flutter Implementation, EPIC-04 (US-04.4, US-04.6) |
| **RAH-DOC-005 reference** | N/A — new constraint; no source-document value exists for either decision below |
| **Related** | [Sequence Diagrams §1](../architecture/sequence-diagrams.md#1-qr-scan--payment--unlock-incl-failurerefund-path), [Risk Register R-11/R-12](../decisions/risk-register.md), [ADR-0014](./0014-payment-provider-abstraction.md), [Domain Model §6](../architecture/domain-model.md#6-bounded-context-access--payment), [Wireframes — SCR-017/018/019](../design/wireframes/mobile-emergency-payment.md) |

## Context

Two values the QR-scan-to-unlock flow (Sequence Diagram §1) depends on are undefined anywhere in the approved documentation:

1. **Unlock-wait timeout.** The sequence diagram models an `alt Unlock acknowledged / Unlock times out or fails` branch, but assigns no numeric bound. Risk Register R-11 ("MQTT broker and IoT ingestion service must handle unlock/alert commands reliably... define SLA with RAH-DOC-004 hardware team") is explicitly listed as only **partially mitigated** — the SLA itself has never been set. No IoT ingestion service, MQTT broker, or hardware SLA exists anywhere in this repository to derive a real value from.
2. **Stale/abandoned-session handling.** Neither the ERD, the OpenAPI spec, nor the wireframes define any automatic session-close or timeout policy. SCR-017/SCR-019 specify exactly two paths to session completion: an automatic transition on a door-sensor-close broadcast, and a manual "J'ai terminé" button — nothing else.

EPIC-04's US-04.4 (unlock request) and US-04.6 (auto-release on close) cannot be implemented without the mobile app taking *some* stance on both. The pre-implementation architecture review confirmed neither is a structural blocker — both are implementation-detail gaps that the mobile team is authorized to close with a documented, temporary, and replaceable decision, not a silently invented product behavior.

## Decision

### Decision 1 — Unlock-wait timeout: temporary, configurable, 30 seconds

The mobile app applies a **client-side-only** wait bound of **30 seconds**, starting when the app begins awaiting the unlock outcome (immediately after `POST /access-sessions/{id}/payments` for paid cabins, or immediately after session initiation for free cabins) and ending on whichever comes first: an `unlocked`/`payment_failed`/`UNLOCK_FAILED_REFUNDED` result, or the 30-second bound.

- Displayed via SCR-017's determinate 4-step progress indicator (Component Library §7) — never an indeterminate spinner for this wait.
- If no confirmation arrives within 30 seconds, the app locally transitions to the documented unlock-failure flow (SCR-018, unlock-failed/refund variant) — it does **not** invent a new UI state.
- The value is declared once, as a named, documented constant (not a literal scattered across call sites), so it is trivially replaceable.
- **This is a UX bound, not a cancellation.** The client timing out locally does not cancel, roll back, or assume authority over the backend/IoT operation — the backend's refund-on-failure path (ADR-0014, R-12) is authoritative and continues independently. If the real outcome (success or refund) arrives after the local 30s window already showed a failure state, the app must still reconcile to the authoritative status on the next Realtime broadcast or poll (§5 of the approved architecture review) — a late "actually it unlocked" must correct the UI, not be discarded.
- This value **must be replaced** once a real backend/hardware SLA is defined (R-11's still-open mitigation item) — this ADR is intentionally provisional and should be revisited at that time, not treated as a permanent architectural decision.

### Decision 2 — Stale session: no invented auto-close policy

The mobile app implements **no automatic session-close, no countdown, and no "assume ended after N minutes" logic** anywhere in the Access & Payment feature. Until a documented backend/product policy exists, the app follows exactly what the approved wireframes specify and nothing more:

- The manual **"J'ai terminé"** action (SCR-017) remains the user's only self-service way to reach SCR-019 absent a sensor event.
- The app reacts immediately to the real `CabinOccupancyChanged(free)` broadcast (or its simulated equivalent against the mock adapter) the moment it arrives, however long that takes.
- This is documented in code (a comment on the relevant provider/use case) and in `docs/phase-3-implementation-log.md` as an **explicit V1 implementation limitation** — a session abandoned without either event (e.g., app killed mid-session) has no self-healing story yet — not as intended product behavior, and not silently glossed over.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **30s client-side unlock timeout (chosen)** | Bounds SCR-017's progress indicator as the wireframe implies; consistent order-of-magnitude with typical IoT command-ack latency; isolated to one named constant, cheap to replace | Not derived from any measured SLA — an explicitly flagged judgment call, same category as ADR-0025's 15° calibration threshold |
| No timeout — wait indefinitely on Realtime/poll only | Never a false-positive failure | Leaves SCR-017 in an unbounded "progress" state with no path to the documented SCR-018 failure branch; poor UX; inconsistent with the sequence diagram's explicit failure branch |
| Short timeout (5–10s) | Fails fast | High false-positive rate — MQTT round-trip + physical lock actuation plausibly exceeds a page-load-class interval, causing needless refund-flow churn |
| Adaptive/exponential timeout | More "correct" eventually | Premature — no real latency data exists yet to calibrate against; adds complexity with no evidence behind it |
| Invented client-side stale-session auto-close (e.g. 15 min) | Gives the app a self-healing story now | Explicitly rejected — no source document specifies this; would silently define product behavior no one has approved, exactly what this review was convened to avoid |
| Manual action only, no fallback (chosen for Decision 2) | Matches exactly what the wireframes specify, nothing invented | Abandoned sessions have no automatic resolution in V1 — accepted as a documented limitation |
| Block the UI until the session resolves | N/A | Rejected outright — traps the user with no exit |

## Consequences

### Positive
- Both temporary values are isolated and named, not scattered magic numbers — replacing them with a real SLA/policy later touches one declaration each, not the domain or UI layers.
- No product behavior is invented beyond what the approved wireframes and sequence diagrams already specify — Decision 2 in particular keeps the mobile team inside its authority.
- The refund-on-unlock-failure path (R-12, ADR-0014) remains fully server-authoritative; Decision 1 only changes when the *mobile UI* stops waiting, never the backend's actual handling.

### Negative / Trade-offs
- 30 seconds is a placeholder, not a measured value — it may prove too short or too long once a real IoT/hardware SLA exists (R-11 still open) and will need revisiting.
- A client-side timeout showing "failed" is not proof the backend/IoT operation actually failed — implementers must handle the late-arriving authoritative status correctly (§ Decision 1) rather than treating the local timeout as final.
- No stale-session cleanup means a genuinely abandoned session has no client-side resolution in V1 — a known, explicitly documented limitation carried forward for product/backend follow-up, not a defect to silently work around.

## Related
- `lib/features/access_payment/` (to be created)
- `docs/phase-3-implementation-log.md` (Decision 2's limitation to be restated there once US-04.4/04.6 are implemented)
- Supersedes no prior ADR; narrows the previously-undefined behavior left open by [ADR-0014](./0014-payment-provider-abstraction.md) and Risk Register R-11/R-12
