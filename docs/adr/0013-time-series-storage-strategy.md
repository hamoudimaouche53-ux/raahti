# ADR-0013: Time-Series Telemetry Storage — Native PostgreSQL Range Partitioning

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **Phase** | Phase 1 — System Architecture |
| **Resolves** | [ADR-0004](./0004-database-strategy.md) (previously Proposed), [Architecture Overview OQ6](../architecture/architecture-overview.md#9-open-questions), Risk Register R-04 |

## Context
[ADR-0004](./0004-database-strategy.md) left the time-series engine for `telemetry_reading` ([ERD §3.13](../erd/erd.md#313-telemetry-reading-new--supports-fr-cld-01-8-capteurs)) open between a TimescaleDB extension and a dedicated TSDB. Phase 1's explicit constraint is to **maintain compatibility with Supabase (PostgreSQL + PostGIS)** — Supabase's managed Postgres offering does not support the TimescaleDB extension (it is not on Supabase's supported-extensions list), which rules out that option without self-hosting Postgres and abandoning Supabase as the BaaS ([ADR-0005](./0005-baas-platform-supabase.md)). A separate dedicated TSDB would add a second operational data store outside Supabase, contradicting the single-Cloud-platform posture of RAH-DOC-005 §6.

## Decision
Store `telemetry_reading` in the **same Supabase PostgreSQL instance**, using **native declarative range partitioning** on `recorded_at` (monthly partitions), with old partitions rolled off to cold storage (Supabase Storage export) per the retention policy in [Deployment Architecture](../deployment/deployment-architecture.md#backup--retention). Partition management uses either `pg_partman` (if available on the Supabase extension allowlist at implementation time) or a scheduled `pg_cron` job that creates the next partition ahead of need — `pg_cron` **is** supported on Supabase. Query performance for time-bounded telemetry reads (e.g. per-station occupancy history for FR-OPS-04) is achieved through partition pruning plus a composite index on `(station_id, recorded_at)`.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Native Postgres partitioning (chosen) | Fully compatible with managed Supabase, no new infra, single Cloud platform preserved (§6) | Manual/pg_cron-driven partition lifecycle management instead of a purpose-built TSDB's automation |
| TimescaleDB extension | Purpose-built time-series performance/compression | Not supported on managed Supabase — would force self-hosting, contradicting the Phase 1 Supabase-compatibility constraint |
| Dedicated external TSDB (e.g. InfluxDB) | Best-in-class time-series performance at very high scale | Second operational data store, additional integration/ops burden not justified at V1 station-fleet scale; splits the "single aggregation point" principle of §6 |

## Consequences
### Positive
- Zero new infrastructure; stays entirely within the confirmed Supabase platform.
- `telemetry_reading` remains joinable in the same database as `station`/`cabin` for operator-facing occupancy history queries (FR-OPS-04), without cross-store stitching.

### Negative / Trade-offs
- At very high station-fleet scale, native partitioning may eventually need revisiting (e.g. read-replica offload or a dedicated store) — explicitly flagged as a future scalability checkpoint in [Deployment Architecture](../deployment/deployment-architecture.md#scalability), not a V1 concern.

## Related
- [ADR-0004](./0004-database-strategy.md) (superseded on this point), [ERD §3.13](../erd/erd.md#313-telemetry-reading-new--supports-fr-cld-01-8-capteurs), [Deployment Architecture](../deployment/deployment-architecture.md)
