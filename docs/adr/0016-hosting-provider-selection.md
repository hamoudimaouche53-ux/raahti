# ADR-0016: Backend Hosting Provider — Indicative, Region-Constrained

| | |
|---|---|
| **Status** | Proposed (indicative shortlist) — final provider approval required before Phase 3 |
| **Date** | 2026-07-31 |
| **Deciders** | *(Pending: Engineering + Business — provider cost/compliance review)* |
| **Phase** | Phase 1 — System Architecture |
| **RAH-DOC-005 reference** | §7 ("infrastructure Cloud avec présence régionale proche du marché algérien pour la latence, plan de reprise d'activité formalisé") |

## Context
RAH-DOC-005 §7 requires regional Cloud presence near Algeria for latency, and a formal disaster-recovery plan. Supabase itself is hosted on AWS infrastructure with a defined set of regions; the NestJS backend container ([ADR-0012](./0012-backend-framework-selection.md)) needs a hosting target co-located as close as possible to whichever Supabase region is selected, to avoid adding cross-region latency on every request.

## Decision
This ADR is **intentionally left Proposed, not Accepted** — final selection requires a cost/compliance decision this architecture is not authorized to make unilaterally (mirroring the payment-provider and diabetic-verification deferrals). It fixes the **decision criteria and shortlist** so Phase 3 can decide quickly:

**Criteria**: (1) network latency from Algeria, (2) container/runtime support for a Dockerized NestJS service, (3) managed CI/CD integration, (4) cost at V1-appropriate scale, (5) compatibility with the Supabase region chosen.

**Shortlist** (indicative, not a decision):
| Candidate | Notes |
|---|---|
| AWS (eu-west-3 Paris, or eu-south-1 Milan) | Likely lowest latency to Algeria among major hyperscalers; natural fit if Supabase's underlying region is also AWS-based |
| OVHcloud (Marseille/Gravelines) | Strong existing network presence in North Africa/Algeria; French-market operational familiarity |
| Fly.io / Render (container PaaS) | Fast to deploy, less infra management overhead; smaller footprint, may be sufficient at V1 traffic |

## Alternatives Considered
Not applicable in the traditional sense — this ADR documents a shortlist pending an explicit business decision, per this phase's instruction not to assume a specific vendor without approval.

## Consequences
### Positive
- Unblocks Deployment Architecture design (container-based, environment-agnostic) without waiting on the vendor decision.
- Deployment Architecture ([docs/deployment/deployment-architecture.md](../deployment/deployment-architecture.md)) is written to be portable across any of the shortlisted candidates (Docker + standard CI/CD), so the eventual choice does not require an architecture rewrite.

### Negative / Trade-offs
- Exact latency figures and disaster-recovery region pairing cannot be finalized until a candidate is chosen — tracked in the Risk Register (R-09) and the Phase 1 open questions.

## Related
- [Deployment Architecture](../deployment/deployment-architecture.md), [ADR-0005](./0005-baas-platform-supabase.md), Risk Register R-09
