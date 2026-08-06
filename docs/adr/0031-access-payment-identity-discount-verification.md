# ADR-0031: Access & Payment ↔ Identity — Server-Side Emergency Discount Re-Verification

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-06 |
| **Deciders** | Engineering team |
| **RAH-DOC-005 reference** | §2.4 (Mode Urgence) |
| **Phase** | Phase 4 — Backend Implementation |

## Context

[`domain-model.md`](../architecture/domain-model.md) §7 (Emergency Mode) states that `EmergencyDiscountPolicy` "reads `Identity & Access`'s `DiabeticVerificationStatus`, yields a `DiscountRate` **consumed by `Access & Payment`**." That sentence implies a data flow from Emergency into Access & Payment.

But two other, more authoritative documents disagree with a literal reading of that sentence:

- [`module-dependency-diagram.md`](../architecture/module-dependency-diagram.md) §3's CI-enforced matrix has **no cell** for `EmergencyModule ↔ AccessPaymentModule` in either direction, and (until this ADR) granted `AccessPaymentModule` **no edge to `IdentityModule`** at all.
- `AuthorizeAndCapturePaymentService`'s own prior doc comment (Emergency module, Phase 4 kickoff pass) already flagged this exact gap explicitly: `applyEmergencyDiscount` (`PaymentRequest.applyEmergencyDiscount` per `openapi.yaml`) was accepted but was a **documented V1 no-op**, because Identity was not a sanctioned read dependency for `AccessPaymentModule` and the flag could not be safely evaluated.

This ADR records how that gap is closed, now that `EmergencyModule` itself has been implemented (`GET /emergency/nearest-facility`, FR-EMG-01/02) and `AuthorizeAndCapturePaymentService`'s no-op needs to become a real discount application per `openapi.yaml`'s already-authored description of `POST /access-sessions/{id}/payments`: *"Applies the Mode Urgence 50% discount (FR-EMG-03) automatically when the caller's diabeticVerificationStatus = verified and the request originated from the Emergency flow."*

## Decision

1. **Grant `AccessPaymentModule` a new `✔(read)` edge to `IdentityModule`'s already-exported `UserQueryService`**, mirroring the pre-existing `Notif -.->|read| Identity` edge exactly — this is a new *instance* of an established pattern (module-dependency-diagram.md §3), not a new kind of dependency. `AuthorizeAndCapturePaymentService` now injects `UserQueryService` and calls `findById(callerId)` before pricing a paid-cabin transaction.

2. **`AccessPaymentModule` gets NO edge to `EmergencyModule`** — the matrix is *not* amended to add `AccessPay ↔ Emergency` in either direction, and a corresponding eslint `import/no-restricted-paths` zone enforces that nothing may import `emergency/` at all (mirroring the existing "nothing may depend on Slatoki/Notifications/Operations" zones). The two modules independently apply the same FR-EMG-03 invariant (`diabeticVerificationStatus === 'verified'`) against Identity's data at two different, asynchronous points in the user journey:
   - **Read time** — `GET /emergency/nearest-facility` reports `discountEligible` as an informational flag when the user taps "Urgence" (Sequence Diagrams §2).
   - **Write time** — `POST /access-sessions/{id}/payments` independently re-derives eligibility and actually prices the transaction, regardless of whether the caller went through the Emergency flow's GET first.

   `AuthorizeAndCapturePaymentService` duplicates `EmergencyDiscountPolicy`'s one-line `status === 'verified'` check locally (`EMERGENCY_DISCOUNT_PERCENTAGE` + the check, in `authorize-and-capture-payment.service.ts`) rather than importing the class, precisely because there is no sanctioned edge to import it *through* — `EmergencyModule` has no incoming edges in the matrix (module-dependency-diagram.md §3), by design, since it is pure read-side orchestration with no persisted state and no reason to be a dependency of anything.

3. **`AccessPaymentModule` independently re-verifies `diabeticVerificationStatus` server-side rather than trusting the client's `applyEmergencyDiscount` boolean unchecked** — a deliberate hardening beyond the literal `sequence-diagrams.md` §2 diagram (which only shows the GET-time eligibility check), justified because this endpoint gates a real monetary discount (Risk Register R-01: diabetic-verification mechanism/discount is explicitly risk-flagged). An ineligible caller who still sends `applyEmergencyDiscount: true` is silently charged full price — the flag is a hint, never a trusted authorization.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| `AccessPay -.->|read| Identity` + independent re-verification (chosen) | Closes the flagged V1 no-op gap with a single new instance of an already-established edge pattern; no coupling to `EmergencyModule`'s existence/lifecycle; server-side re-verification is correct regardless of which client flow set the flag | `IdentityModule`'s `UserQueryService` gains a second consumer; the FR-EMG-03 percentage/eligibility check is duplicated in two files instead of shared |
| Grant a live `AccessPay ↔ Emergency` edge to literally reuse `EmergencyDiscountPolicy` | Single source of truth for the discount logic | Requires inventing a synchronous or event-based coupling with no documented consumer/producer semantics — the `EmergencyModeActivated` domain event in `domain-model.md` §7 is never referenced by any sequence diagram or matrix edge, so wiring one here would be inventing scope, not implementing it; also contradicts the matrix's explicit "Emergency has no sanctioned incoming edges" design |
| Leave `applyEmergencyDiscount` a permanent no-op | No new dependency at all | Contradicts `openapi.yaml`'s own already-authored `POST /access-sessions/{id}/payments` description (discount applied "automatically"); contradicts the backlog's US-03.3 "Representative Tasks" line, which explicitly instructs wiring the discount into "Access & Payment's transaction pricing step" |

## Consequences

### Positive
- Closes the flagged no-op gap without coupling `AccessPaymentModule` to `EmergencyModule`'s existence or lifecycle.
- The discount is enforced server-side against authoritative Identity data, not trusted from client input — appropriate given this gates a real monetary amount.
- `EmergencyModule` remains exactly what `module-dependency-diagram.md` §5 rule 3 says an orchestration module should be: no owned state, no incoming edges, trivially removable/replaceable.

### Negative / Trade-offs
- `IdentityModule`'s `UserQueryService` now has a second consumer (`NotificationsModule` was the first) — a small increase in its "blast radius" if its contract ever changes.
- `AccessPaymentModule`'s import list grows by one (`IdentityModule`), and its own `authorize-and-capture-payment.service.ts` duplicates `EmergencyDiscountPolicy`'s one-line eligibility check rather than sharing it — an accepted, documented duplication (both files comment on it), not an oversight.

## Related
- [ADR-0014](./0014-payment-provider-abstraction.md) (Payment Provider Abstraction)
- [ADR-0029](./0029-places-query-composition.md) (Places Query Composition — the precedent this ADR's "narrowly-scoped new edge, mirror an existing pattern" reasoning follows)
- [Domain Model §6, §7](../architecture/domain-model.md)
- [Module Dependency Diagram](../architecture/module-dependency-diagram.md)
- [Sequence Diagrams §2](../architecture/sequence-diagrams.md)
- Risk Register R-01
