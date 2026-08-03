# ADR-0008: Offline-First Data Sync Strategy (Mobile)

| | |
|---|---|
| **Status** | Accepted (strategy and implementation — local-cache technology finalized by [ADR-0022](./0022-offline-cache-implementation-and-recenter-tracking.md)) |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **RAH-DOC-005 reference** | §2.1 ("Mode hors connexion"), §9 ("plan de dégradation gracieuse... cache local") |

## Context
RAH-DOC-005 requires the map to show cached data on connectivity loss with a freshness indicator (§2.1, FR-MAP-07), and requires graceful degradation platform-wide (§9, NFR-AVAIL-02). The Master Roadmap explicitly names "Offline" as a Phase 5 mobile deliverable and "Offline-First" as a Phase 1 architectural principle.

## Decision
The mobile app maintains a **local read cache** (candidate: Drift/Isar on top of SQLite) of nearby stations, cabins, and third-party places, refreshed opportunistically whenever connectivity and Realtime subscriptions are available. Read paths (map, place detail) always serve from local cache first, annotated with a `last_synced_at` freshness indicator (FR-MAP-07). **Write paths that require server authority (payment, unlock) are never queued offline** — they fail fast with a clear "connectivity required" state, since RAH-DOC-005 does not describe offline payment/unlock as a requirement, and queuing a physical unlock order offline would be a safety/consistency risk.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Read-cache only, no offline writes (chosen) | Matches stated requirements exactly; avoids unsafe offline unlock/payment semantics | Users cannot initiate access sessions with zero connectivity |
| Full offline-first with queued writes (e.g. CRDT sync) | Would support offline payment/unlock queuing | Not requested by RAH-DOC-005; introduces physical-safety and double-spend risk for an unlock/payment domain |

## Consequences
### Positive
- Directly satisfies FR-MAP-07 and NFR-AVAIL-02 without over-building.
- Keeps the safety-critical unlock/payment flow (FR-PAY-01…06) strictly online, avoiding a whole class of sync-conflict bugs.

### Negative / Trade-offs
- ~~Local cache technology (Drift vs. Isar vs. other) is not finalized — Phase 1/5 implementation detail.~~ Resolved: Drift, per [ADR-0022](./0022-offline-cache-implementation-and-recenter-tracking.md).

## Related
- [SRS FR-MAP-07, NFR-AVAIL-02](../srs/SRS.md), [Architecture Overview §5](../architecture/architecture-overview.md#5-cross-cutting-concerns)
