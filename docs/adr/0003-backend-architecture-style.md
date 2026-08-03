# ADR-0003: Backend Architecture Style — Modular Monolith, DDD Bounded-Context Modules, Microservices-Ready

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **RAH-DOC-005 reference** | §7 (indicative: "architecture par microservices") |

## Context
RAH-DOC-005 §7 indicatively recommends a microservices architecture "pour séparer gestion des stations, paiement, utilisateurs et notifications," explicitly flagged as needing validation with the engineering team. The Master Roadmap Phase 1 commits to DDD and Clean Architecture but does not mandate a specific deployment topology. At V1, the RAHATI system has a bounded team and a moderate number of bounded contexts (10, see [Domain Model](../architecture/domain-model.md)); a full microservices deployment (independent services, inter-service network calls, distributed transactions) introduces operational overhead — service discovery, distributed tracing, data consistency across service boundaries — that is disproportionate to V1 team size and traffic.

## Decision
Build the backend as a **modular monolith**: one deployable API Backend container, internally organized into modules that map 1:1 to DDD bounded contexts (see [C4 Component diagram](../architecture/c4-component.md)), each with its own persistence-port boundary. Module boundaries are enforced at the code level (no cross-context direct repository access — only via published application services/events), so any module can be extracted into an independent microservice later with minimal rework. This **operationalizes**, rather than contradicts, §7's microservices recommendation: it is the recommended evolutionary path for a system starting at RAHATI's current scale.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Full microservices from day one | Matches §7 literally; independent scaling/deployment per context | High operational overhead for V1 team size; distributed-transaction complexity for Access & Payment ↔ Station Network ↔ Notifications flows |
| Unstructured monolith (no module boundaries) | Fastest initial development | Violates DDD/Clean Architecture mandate; blocks future extraction |
| Modular monolith, microservices-ready (chosen) | Matches DDD/Clean Architecture mandate; low operational overhead now; extraction path preserved | Requires discipline to keep module boundaries honest without service-level enforcement |

## Consequences
### Positive
- Single deployment/CI pipeline at V1 (simpler Phase 3/13 operations).
- Strict module boundaries mean any bounded context (e.g. Access & Payment, given its payment-provider ACL) can become an independent service later without a rewrite.

### Negative / Trade-offs
- Requires code-review discipline to prevent modules from bypassing their ports (no compiler-enforced network boundary as true microservices would have).

## Related
- [Architecture Overview §2](../architecture/architecture-overview.md#2-system-layers-clean-architecture), [C4 Component](../architecture/c4-component.md), [Domain Model](../architecture/domain-model.md)
