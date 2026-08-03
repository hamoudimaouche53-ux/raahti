# ADR-0007: API Style — REST

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **RAH-DOC-005 reference** | §7 (indicative: "API REST ou GraphQL") |

## Context
RAH-DOC-005 §7 leaves the API style indicative between REST and GraphQL. The consuming clients are a Flutter mobile app (offline-first, needing predictable per-resource caching per FR-MAP-07), a website, and two dashboards with comparatively simple, well-bounded data needs (fleet status, aggregated sponsor reports) rather than deeply nested, client-driven query shapes.

## Decision
Use **REST** as the primary API style for all client-backend communication, versioned (`/v1/...`), following API-First practice (OpenAPI contract authored before implementation, per Master Roadmap Phase 1). GraphQL is not adopted for V1; it may be reconsidered for a specific aggregation-heavy surface (e.g. Sponsor Dashboard reporting) in a later phase if REST proves insufficient there.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| REST (chosen) | Simple per-resource HTTP caching, fits offline-first sync (ADR-0008); mature tooling; easier versioning story | Potential over-/under-fetching for dashboard aggregate views |
| GraphQL | Flexible client-driven queries; single endpoint | Caching/offline story is more complex to build correctly; added schema/runtime complexity not justified by V1 client needs |

## Consequences
### Positive
- Matches the Offline-First mandate (Master Roadmap Phase 1) more directly than GraphQL would.
- Each bounded-context module ([ADR-0003](./0003-backend-architecture-style.md)) maps cleanly to a REST resource group.

### Negative / Trade-offs
- Sponsor/Operator dashboard aggregate views may require purpose-built aggregation endpoints rather than free-form queries.

## Related
- [Architecture Overview §4](../architecture/architecture-overview.md#4-technology-stack), `docs/api/` (populated Phase 1)
