# ADR-0030: Lock Control Abstraction — Provider-Agnostic Unlock-Dispatch Port

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-06 |
| **Deciders** | Engineering team |
| **Phase** | Phase 4 — Backend Implementation, EPIC-04 (Access & Payment) |
| **RAH-DOC-005 reference** | §2.5 (steps 3–4: unlock dispatch and acknowledgement — no IoT/MQTT implementation detail specified) |

## Context

The QR-scan-to-unlock flow ([Sequence Diagrams §1](../architecture/sequence-diagrams.md#1-qr-scan--payment--unlock-incl-failurerefund-path)) models the API backend issuing an unlock order to an "IoT Ingestion Service", which publishes an MQTT command to the station lock and relays back an acknowledgement or failure. No IoT ingestion service, MQTT broker, or any hardware-integration code exists anywhere in this repository — IoT Platform is Master Roadmap Phase 9, entirely unbuilt (0 files), and [Risk Register R-11](../decisions/risk-register.md) explicitly lists the MQTT/unlock-command SLA as still open, only "partially mitigated" by the refund-on-failure design.

`AccessPaymentModule` (Domain Model §6) is V1-critical (EPIC-04) and cannot be built or tested — including its most important edge case, the [R-12](../decisions/risk-register.md) refund-on-unlock-failure path — without *some* unlock-dispatch implementation available now. Waiting for Phase 9 IoT to exist first would block a V1-critical epic indefinitely on unrelated, unscheduled hardware-integration work. This is the exact same situation [ADR-0014](./0014-payment-provider-abstraction.md) resolved for the payment provider: build the module against a stable port now, swap in a real adapter later with zero changes to domain/application code.

## Decision

`AccessPaymentModule` depends only on a domain-owned **`LockControlGateway` port** (interface), never on a concrete MQTT client, IoT ingestion service SDK, or hardware protocol:

```ts
export interface UnlockOrderResult {
  result: 'unlocked' | 'failed';
  acknowledgedAt: Date | null;
}

export interface LockControlGateway {
  issueUnlockOrder(params: { cabinId: string; accessSessionId: string }): Promise<UnlockOrderResult>;
}
```

- `AuthorizeAndCapturePaymentService` (the only application-layer use case that needs unlock dispatch) depends only on this interface (Dependency Inversion, Clean Architecture) — exactly mirroring how it depends on `PaymentGateway` for payment, never a concrete provider SDK.
- A concrete `<Vendor>LockControlAdapter` class in the Infrastructure layer will implement the port once Phase 9's IoT ingestion service (and its MQTT command contract) exists; it is the **only** place IoT/MQTT-specific code may appear.
- `MockLockControlAdapter` (deterministic, in-memory, constructor-configurable outcome — default always `'unlocked'` with an immediate acknowledgement, or forced to `'failed'` for testing) is used for all development, testing, and demo environments until Phase 9 ships — same treatment as `MockPaymentGatewayAdapter` (ADR-0014) and the `MockPlaceDetailRepository` precedent ([ADR-0023](./0023-explicit-mock-adapter-for-place-detail.md)).
- The refund-on-unlock-failure path (Risk R-12) is fully exercisable today: `AuthorizeAndCapturePaymentService`'s unit and e2e tests configure `MockLockControlAdapter` to return `'failed'` and assert `PaymentGateway.refund()` is called and the `Transaction` ends `refunded`, not `captured` — the single most important test in the module.
- The client-side 30-second unlock-wait timeout ([ADR-0026](./0026-unlock-timeout-and-stale-session-handling.md)) is this port's counterpart on the mobile side — that ADR bounds how long the *app* waits for a result; this ADR defines the *backend's* dispatch contract that eventually produces one. Neither ADR assumes the other's numeric value.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| Port/adapter abstraction with a mock implementation (chosen) | Fully hardware-agnostic; unblocks Access & Payment development now; R-12's refund path is genuinely testable today; matches ADR-0014's already-accepted precedent exactly | Slight abstraction overhead; the real Phase 9 adapter's exact params (beyond `cabinId`/`accessSessionId`) can't be finalized until the MQTT command schema is designed |
| Wait for Phase 9 IoT ingestion service before building Access & Payment | Simpler, no abstraction needed | Blocks a fully-specified, V1-critical epic (EPIC-04) on entirely unscheduled hardware-integration work (Phase 9) — unacceptable schedule risk, same category of risk ADR-0014 rejected this option for |
| Stub unlock as always-succeeding, with no port at all (inline `true` in the service) | Fastest to write | Makes R-12's refund-on-failure path untestable — there would be no way to deterministically force a failure outcome, leaving the module's most important edge case unverified; also couples the application service to a hard-coded assumption instead of an injectable dependency, violating this codebase's Clean Architecture rule (System Architecture §3) |

## Consequences

### Positive
- No architectural work on `AccessPaymentModule` is blocked by Phase 9 IoT not existing yet.
- Risk R-12 (payment captured, unlock fails) is fully mitigated in code today, not just "architected" on paper — the refund path has real, passing tests.
- When Phase 9's IoT ingestion service is built, only one new Infrastructure-layer adapter class and its tests are needed — zero changes to `AccessPaymentModule`'s domain or application layers.

### Negative / Trade-offs
- `MockLockControlAdapter`'s always-succeeding default and immediate synchronous resolution do not model real MQTT round-trip latency, retries, or partial-acknowledgement edge cases — those can only be validated once a real adapter exists.
- The port's parameter shape (`cabinId`, `accessSessionId`) is a reasonable minimum guess at what an IoT command needs to carry; the real Phase 9 MQTT command schema may require additional fields (e.g. a station-level hardware address), which would be an additive, backward-compatible change to this interface, not a breaking one.

## Related
- [ADR-0014](./0014-payment-provider-abstraction.md) — the payment-provider abstraction this ADR directly mirrors.
- [ADR-0023](./0023-explicit-mock-adapter-for-place-detail.md) — prior precedent for an explicit, clearly-labeled mock adapter standing in for unbuilt infrastructure.
- [ADR-0026](./0026-unlock-timeout-and-stale-session-handling.md) — the client-side unlock-wait timeout counterpart.
- [Risk Register R-11/R-12](../decisions/risk-register.md).
- [Domain Model §6](../architecture/domain-model.md#6-bounded-context-access--payment).
- [Sequence Diagrams §1](../architecture/sequence-diagrams.md#1-qr-scan--payment--unlock-incl-failurerefund-path).
