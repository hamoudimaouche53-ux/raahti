# ADR-0014: Payment Provider Abstraction — Provider-Agnostic Adapter Pattern

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **Phase** | Phase 1 — System Architecture |
| **RAH-DOC-005 reference** | §7, §11 (provider selection explicitly deferred) |

## Context
The payment provider is explicitly not yet selected (PRD OQ2, Risk R-02) and its selection is out of this architecture's authority to decide. Phase 1 must nonetheless produce an implementation-ready Access & Payment module ([Domain Model §6](../architecture/domain-model.md#6-bounded-context-access--payment)) without hard-coding any vendor, per this phase's explicit instruction to remain provider-agnostic and document the extension point clearly.

## Decision
The `Access & Payment` module depends only on a domain-owned **`PaymentGateway` port** (interface), never on a concrete provider SDK:

```
interface PaymentGateway {
  authorize(amount: Money, paymentMethodRef: string, idempotencyKey: string): Promise<AuthorizationResult>
  capture(authorizationId: string): Promise<CaptureResult>
  refund(captureId: string, amount: Money): Promise<RefundResult>
  tokenizePaymentMethod(rawMethodToken: string): Promise<PaymentMethodRef>
}
```

- All application-layer use cases (`InitiateAccessSession`, `AuthorizePayment`, `CaptureAndUnlock`, `RefundOnUnlockFailure`) depend only on this interface (Dependency Inversion, Clean Architecture).
- A concrete `<Provider>PaymentGatewayAdapter` class in the Infrastructure layer implements the port once a provider is selected; it is the **only** place provider-specific SDK code may appear.
- `payment_method.provider_ref` ([ERD §3.8](../erd/erd.md#38-payment-method-new--supports-26-moyens-de-paiement-enregistrés)) and `transaction.provider_ref` ([ERD §3.10](../erd/erd.md#310-access-session--transaction-src-ext)) store only opaque, provider-issued tokens — never raw card data — so the schema itself is provider-agnostic.
- A `MockPaymentGatewayAdapter` (deterministic, in-memory) is used for all Phase 1–era development, testing, and demo environments until a provider is approved, so that the rest of the system (Access & Payment, Emergency Mode discount application, Notifications) can be built and tested in full **before** a vendor decision is made — decoupling the payment-provider timeline from the rest of Phase 4 delivery.
- The **refund-on-unlock-failure** path (Risk R-12) is modeled explicitly in the port (`refund`) and in the `AccessSession` state machine ([Domain Model §6 invariants](../architecture/domain-model.md#6-bounded-context-access--payment)), so this edge case is architected for now rather than retrofitted later.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Port/Adapter abstraction (chosen) | Fully provider-agnostic; unblocks development now; matches Phase 1's explicit instruction | Slight abstraction overhead; provider-specific features not in the common interface need a documented escape hatch (below) |
| Wait for provider selection before building Access & Payment | Simpler, no abstraction needed | Blocks a fully-specified, V1-critical epic (EPIC-04) on an external business decision — unacceptable schedule risk (Risk R-02) |

## Extension Point for Provider-Specific Features
If a selected provider offers a capability outside the common `PaymentGateway` interface (e.g. a specific local wallet flow), it is added as an **optional, provider-tagged capability method** (e.g. `supportsCapability('dz_wallet_x')`) queried at runtime by the Application layer — the core authorize/capture/refund/tokenize contract never grows provider-specific parameters.

## Consequences
### Positive
- No architectural work is blocked by the open payment-provider decision.
- When a provider is approved, only one new Infrastructure-layer adapter class and its tests are needed — zero changes to Domain or Application layers.

### Negative / Trade-offs
- The common interface is deliberately conservative (authorize/capture/refund/tokenize); provider-specific richer features require the capability-flag escape hatch above, adding minor design overhead.

## Related
- [Domain Model §6](../architecture/domain-model.md#6-bounded-context-access--payment), [ERD §3.8, §3.10](../erd/erd.md), [Sequence Diagrams — QR-to-Unlock flow](../architecture/sequence-diagrams.md), Risk Register R-02, R-12
