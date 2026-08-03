# ADR-0005: BaaS Platform — Supabase

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **RAH-DOC-005 reference** | §7 ("infrastructure Cloud avec présence régionale... plan de reprise d'activité") — Supabase itself is not named in RAH-DOC-005 |

## Context
RAH-DOC-005 §7 states generic Cloud-hosting requirements (regional presence, disaster-recovery plan) without naming a provider. The Master Roadmap Phase 3 explicitly names **Supabase** (Auth, Storage, Realtime, plus CI/CD, Monitoring, Backups) as the target platform. This ADR records that as a confirmed decision and reconciles it with §7's generic language.

## Decision
Use **Supabase** as the managed backend-as-a-service platform, providing: PostgreSQL (relational store, [ADR-0004](./0004-database-strategy.md)), Auth (identity provider underlying [ADR-0009](./0009-authentication-and-rbac.md)), Storage (object storage for place photos and verification documents, [ERD §3.9](../erd/erd.md#39-verification-document-new--supports-fr-usr-03)), and Realtime (powering FR-PAY-05 and FR-OPS-01's live status updates).

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Supabase (chosen) | Matches Master Roadmap Phase 3 exactly; Postgres-native; built-in Realtime satisfies live-status requirements with no extra infrastructure | Vendor lock-in to Supabase-specific Realtime/Auth semantics |
| Self-hosted Postgres + custom Auth/Realtime | Full control, no vendor lock-in | Significant additional Phase 3/13 engineering effort not justified for V1 |

## Consequences
### Positive
- FR-PAY-05 ("statut de la cabine mis à jour en temps réel") and FR-OPS-01 are satisfied largely out-of-the-box via Supabase Realtime.
- Regional-hosting requirement (§7) satisfiable via Supabase's available project regions — to be confirmed against Algeria-proximate options in Phase 3.

### Negative / Trade-offs
- Time-series store ([ADR-0004](./0004-database-strategy.md)) may sit outside Supabase if a dedicated TSDB is selected, introducing a second operational surface.

## Related
- [Architecture Overview §4](../architecture/architecture-overview.md#4-technology-stack), [ADR-0004](./0004-database-strategy.md), [ADR-0009](./0009-authentication-and-rbac.md)
