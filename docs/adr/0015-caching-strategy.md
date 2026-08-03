# ADR-0015: Server-Side Caching Strategy — HTTP/CDN Caching First, No Dedicated Cache Store at V1

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **Phase** | Phase 1 — System Architecture |
| **Related** | [SRS NFR-PERF-01](../srs/SRS.md#81-performance-9), [Cross-Cutting Architecture](../architecture/cross-cutting-architecture.md) |

## Context
NFR-PERF-01 requires sub-1.5s map/place-detail responses. Client-side caching for offline resilience is already decided ([ADR-0008](./0008-offline-first-mobile-sync.md)). This ADR addresses **server-side** caching only. A dedicated cache store (e.g. Redis) is not part of the confirmed Supabase-centric stack ([ADR-0005](./0005-baas-platform-supabase.md)), and introducing one at V1 adds an operational component whose necessity is not yet demonstrated by real traffic.

## Decision
At V1, rely on three layers, in order, before introducing a dedicated cache store:
1. **Database-level performance**: the spatial (`GIST`) and composite indexes already specified in the [ERD §5](../erd/erd.md#5-indexing-strategy-summary) for the map/place-detail query paths.
2. **HTTP caching semantics** on read-mostly, low-personalization endpoints (`GET /v1/places/nearby`, `GET /v1/stations/{id}`, third-party place lists): short `Cache-Control: max-age` (seconds-scale, matching real-time freshness needs) plus `ETag`/`If-None-Match` support, so repeated client polling and CDN/edge caching absorb read load without a new backend component.
3. **In-process application-level memoization** (NestJS-native, in-memory, per-instance) for near-static reference data only (e.g. `tag`, `role` lookup tables from the [ERD](../erd/erd.md)) — never for real-time occupancy data, which must always read current state.

**Real-time occupancy/availability data (`cabin.occupancy_status`) is explicitly excluded from all caching layers** beyond the sub-second propagation already provided by Supabase Realtime — caching stale occupancy would directly violate FR-PLC-02 and FR-PAY-05's real-time guarantees.

A dedicated distributed cache (Redis or equivalent) is the documented **first scale-out addition** once production traffic data shows it is needed (see [Deployment Architecture — Scalability](../deployment/deployment-architecture.md#scalability)) — this ADR fixes the V1 posture, not a permanent constraint.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Indexes + HTTP caching + in-process memoization (chosen) | Zero new infrastructure; meets NFR-PERF-01 at V1 scale; keeps Supabase as the only stateful backend dependency | Does not shed load across multiple backend instances (in-process cache is per-instance) |
| Redis from day one | Cross-instance cache sharing, session/rate-limit store | Unjustified operational overhead before real traffic data exists; against the "no infra beyond what's needed" posture used throughout Phase 0/1 |

## Consequences
### Positive
- Meets NFR-PERF-01 without adding operational surface area at V1.
- Clear, explicit scale-out path documented rather than deferred silently.

### Negative / Trade-offs
- Multi-instance deployments (see [Deployment Architecture](../deployment/deployment-architecture.md)) do not share the in-process memoization layer — acceptable since it only covers near-static reference data, not correctness-critical state.

## Related
- [ERD §5](../erd/erd.md#5-indexing-strategy-summary), [Deployment Architecture](../deployment/deployment-architecture.md), [Cross-Cutting Architecture](../architecture/cross-cutting-architecture.md)
