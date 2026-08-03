# ADR-0004: Database Strategy — Polyglot Persistence (Relational + Time-Series)

| | |
|---|---|
| **Status** | Accepted (relational store); time-series engine resolved by [ADR-0013](./0013-time-series-storage-strategy.md) in Phase 1 |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **RAH-DOC-005 reference** | §7 ("base relationnelle... + base orientée séries temporelles") |

## Context
RAH-DOC-005 §7 explicitly requests two data stores: a relational store for transactional data (users, payments, implicit reservations) and a time-series-oriented store for IoT flows (occupancy, sensors). This is not indicative language — it is a stated requirement, unlike the framework/architecture-style items in the same section.

## Decision
- **Relational store**: PostgreSQL, provisioned via Supabase (see [ADR-0005](./0005-baas-platform-supabase.md)), holding all entities in the [ERD](../erd/erd.md) except `telemetry_reading`.
- **Time-series store**: a dedicated engine for `telemetry_reading`, engine TBD between (a) the TimescaleDB extension on the same Postgres instance, or (b) a separate purpose-built TSDB. This sub-decision is **Proposed, not Accepted** — resolution deferred to Phase 1 based on expected telemetry write volume once station count is known (see [Architecture Overview OQ6](../architecture/architecture-overview.md#9-open-questions)).

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| TimescaleDB extension on the primary Postgres | One database to operate; transactional joins possible | Couples telemetry write load to the transactional database's performance |
| Separate dedicated TSDB | Isolates high-volume IoT writes from transactional workload | Adds an operational component; cross-store joins require application-layer stitching |

## Consequences
### Positive
- Matches §7's explicit two-store requirement without over- or under-delivering.
- Keeps the relational schema (ERD) clean of high-volume time-series noise.

### Negative / Trade-offs
- Final engine choice remained open pending Phase 1 volume estimates — flagged, not hidden. **Update (Phase 1)**: resolved in [ADR-0013](./0013-time-series-storage-strategy.md) — native PostgreSQL range partitioning on the same Supabase instance, driven by the Phase 1 constraint to maintain Supabase compatibility (which rules out TimescaleDB on managed Supabase).

## Related
- [ERD §3.13](../erd/erd.md#313-telemetry-reading-new--supports-fr-cld-01-8-capteurs), [ADR-0005](./0005-baas-platform-supabase.md)
