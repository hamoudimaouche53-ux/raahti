# ADR-0029: Places Query Composition — Read-Only Cross-Context Aggregation for Unified Discovery Endpoints

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-05 |
| **Deciders** | Engineering team + user (Phase 4, Facilities module kickoff) |
| **RAH-DOC-005 reference** | N/A — Phase 4 implementation-level gap between two Phase 0/1 documents |
| **Phase** | Phase 4 — Backend Implementation |

## Context

`docs/api/openapi.yaml`'s `GET /places/nearby` returns a single, distance-sorted, cursor-paginated result set that unifies `Station` and `ThirdPartyPlace` rows (`PlaceSummary.placeKind: enum [station, third_party_place]`). Producing that result requires *some* component to read both bounded contexts together.

The architecture documents disagree on whether that is allowed:

- [`domain-model.md`](../architecture/domain-model.md) §3 (Phase 0, status "Draft for Review") states: *"Station Network also exposes a read-only query service consumed by Third-Party Places to produce the unified map/search result."*
- [`module-dependency-diagram.md`](../architecture/module-dependency-diagram.md) §2–§4 (Phase 1, status "Complete", explicitly CI-enforced) — the allowed-dependency matrix has **no cell** for `StationNetwork ↔ ThirdPartyPlaces` in either direction. Its diagram shows only `Slatoki -.->|read| StationNetwork` and `Slatoki -.->|read| ThirdPartyPlaces`.
- [`c4-component.md`](../architecture/c4-component.md)'s component dependency table independently agrees with the matrix: neither Station Network's nor Third-Party Places' listed dependencies include the other.

Two of three documents — both Phase 1, one explicitly CI-enforced — agree the two contexts are mutually isolated; only a single Phase-0-draft sentence claims otherwise. Additionally, [`repository-structure.md`](../architecture/repository-structure.md)'s per-module table restricts even the `interface/` (controller) layer to depending on **"application/ (own module) only"** — so routing the aggregation through either module's own controller would also violate the documented layering, independent of the matrix question. Flagged to the user before implementation (Facilities module kickoff, 2026-08-05); this ADR records the resolution.

## Decision

1. **`StationNetworkModule` and `ThirdPartyPlacesModule` remain fully independent** — the module-dependency-diagram matrix is **not** amended. Neither module imports, calls, or depends on the other's domain, application, or infrastructure layer, in either direction. `domain-model.md` §3's note is treated as stale Phase 0 drafting language, superseded by the Phase 1 matrix and C4 component diagram.
2. A **narrowly-scoped composition layer** is introduced for **read-only, cross-context aggregation only**: a `PlacesQueryService` (with a thin `PlacesController` for `GET /places/nearby`) that is explicitly permitted to depend on both `StationNetworkModule`'s and `ThirdPartyPlacesModule`'s exported query services (`StationQueryService`, `ThirdPartyPlaceQueryService`) — the same "exported `*QueryService`, never a raw repository" discipline [module-dependency-diagram.md §5 rule 1](../architecture/module-dependency-diagram.md#5-rules-enforced-ci--review) already requires of every other sanctioned cross-module dependency.
3. **Scope is limited to reads.** This composition layer is used *only* for `GET /places/nearby` and any future endpoint that is genuinely a unified read model spanning both contexts. It is never used for writes — every write (station registration, cabin status, third-party place submission, reviews, favorites) stays inside its owning bounded context's own module, called through that module's own controller.
4. This composition layer does not become a 13th bounded-context module. It owns no domain/aggregate, no Prisma models, no persisted state — it is pure read-side orchestration (sort-merge two already-independent query results by distance, paginate, filter), analogous in spirit to `AnalyticsModule`'s "read-model/projection, no owned aggregate" pattern ([Domain Model §11](../architecture/domain-model.md#11-bounded-context-analytics--bi)) but scoped to exactly one concern (places discovery) rather than being a general analytics context.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| Composition-only exception, read-only (chosen) | Keeps both bounded contexts fully independent per the CI-enforced matrix; narrowly scoped, easy to review; matches the existing `*QueryService` export discipline | Adds one small non-bounded-context component not literally enumerated in repository-structure.md's module list |
| Amend the dependency matrix to add a StationNetwork↔ThirdPartyPlaces read edge | Lets either module own `/places/nearby` directly, no new component | Contradicts the Phase 1 matrix's own "no cyclic/unnecessary cross-context dependency" intent for two contexts that otherwise have zero business reason to know about each other; a formal amendment to an Accepted, CI-enforced document for one endpoint's convenience |
| Client-side merge (mobile app calls both `/stations`-style and `/third-party-places`-style list endpoints, merges locally) | No backend composition needed at all | Contradicts the already-authored, reviewed `openapi.yaml` contract (`/places/nearby` is a single unified endpoint) — would require an OpenAPI contract change, which needs its own review per api-architecture.md §1; loses server-side distance-sort/pagination correctness across a merged, cursor-paginated set |

## Consequences

### Positive
- No erosion of `StationNetworkModule`/`ThirdPartyPlacesModule` independence — either can still be extracted to a microservice later (ADR-0003's stated goal) without touching this composition layer's contract beyond its two `*QueryService` dependencies.
- The composition layer is small, has no persisted state, and is trivially replaceable if a future architecture revision resolves this differently.

### Negative / Trade-offs
- Introduces one component outside the strict 10-bounded-context + 2-cross-cutting inventory — mitigated by keeping it read-only, stateless, and documented here rather than silently added.
- `pinColor`/`averageRating`/`reviewCount` computation for the merged read model must be duplicated or shared carefully between this composition layer and each module's own detail-endpoint response shaping — tracked as an implementation detail in the Facilities module's own completion notes, not a further architecture decision.

## Related
- [Module Dependency Diagram](../architecture/module-dependency-diagram.md), [Domain Model §3, §5](../architecture/domain-model.md), [C4 Component](../architecture/c4-component.md), [ADR-0003](./0003-backend-architecture-style.md), `docs/phase-4-implementation-plan.md`
