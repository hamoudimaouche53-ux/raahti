# Phase 4 Implementation Plan — Backend

| | |
|---|---|
| **Document ID** | RAH-DOC-043-PHASE-4-PLAN |
| **Phase** | Phase 4 — Backend Implementation (Master Roadmap) |
| **Version** | 1.0 |
| **Status** | Active |
| **Date** | 2026-08-05 |
| **Baseline** | [System Architecture](./architecture/system-architecture.md) · [Module Dependency Diagram](./architecture/module-dependency-diagram.md) · [Repository Structure](./architecture/repository-structure.md) · [API Architecture](./api/api-architecture.md) · [OpenAPI Contract](./api/openapi.yaml) · [ERD](./erd/erd.md) · [Security Architecture](./architecture/security-architecture.md) |

## 1. Scope

Phase 4 builds the NestJS modular-monolith backend (`apps/backend`) against the Phase 0/1 architecture set. Per explicit instruction: no Flutter app changes unless backend integration requires them, existing architecture followed exactly, every backend design document read before code, no assumptions, every implementation verified against the specs.

## 2. Documents Audited

All 27 ADRs (`docs/adr/`), all 14 architecture documents (`docs/architecture/`), `docs/api/api-architecture.md` + `docs/api/openapi.yaml` (contract, full paths/schemas), `docs/erd/erd.md`, `docs/deployment/deployment-architecture.md`, `docs/backlog/product-backlog.md`, `docs/srs/SRS.md` (relevant FR/NFR sections), `docs/decisions/risk-register.md`, and every `README.md` already scaffolded under `apps/backend/src/`. Backend-decisive ADRs: 0003 (modular monolith/DDD), 0004 (Postgres + deferred time-series engine, resolved by 0013), 0005 (Supabase BaaS), 0006 (MQTT), 0007 (REST), 0009 (Supabase Auth + custom RBAC), 0012 (TypeScript/NestJS/Prisma), 0013 (native Postgres partitioning for telemetry), 0014 (payment provider abstraction, provider deferred), 0015 (caching), 0016 (hosting — Proposed, not Accepted, does not block implementation).

## 3. Current Code vs. Documentation

`apps/backend/src/` contains **only** the Phase 1 folder skeleton: `modules/{identity,station-network,third-party-places,slatoki,access-payment,emergency,notifications,sponsorship,operations,analytics}/{domain,application,infrastructure,interface}` (per-module subset per [Repository Structure §3](./architecture/repository-structure.md#3-backend-structure-appsbackend)), `shared-kernel/`, `platform/` — every folder holds exactly one `README.md`, no source code, no `package.json`, no `tsconfig.json`, no Prisma schema, no `main.ts`. This confirms the Phase 1 instruction ("no implementation code yet") was honored exactly and Phase 4 starts from zero application code.

## 4. Module-Mapping Reconciliation

The requested implementation order (Identity & Authentication, Users, Facilities, Slatoki, Reviews, Favorites, Search, Notifications, Administration) does not map 1:1 onto the documented bounded contexts or the already-scaffolded module folders. Per [ADR-0003](./adr/0003-backend-architecture-style.md) and [Module Dependency Diagram §2](./architecture/module-dependency-diagram.md#2-module-list), the backend has exactly 10 bounded-context modules + 2 cross-cutting modules; "Users", "Facilities", "Reviews", "Favorites", "Search", "Administration" are not among them. Cross-checking the authoritative OpenAPI contract (`docs/api/openapi.yaml`) confirms these are **resource groupings within** existing modules, not modules of their own:

| Requested item | Resolves to | Evidence |
|---|---|---|
| Identity & Authentication | `IdentityModule` — AuthN/AuthZ guards, RBAC (`role`/`user_role`) | ADR-0009, Security Architecture §1–2 |
| Users | `IdentityModule` — `/users/me*` (all tagged `Identity` in openapi.yaml) | openapi.yaml L31–139 |
| Facilities | `StationNetworkModule` + `ThirdPartyPlacesModule` — `/places/*`, `/stations/*`, `/third-party-places/*` (all tagged `Places`) | openapi.yaml L141+, Domain Model §3/§5 |
| Slatoki | `SlatokiModule` (no owned aggregate — reads Station/ThirdPartyPlace) | Domain Model §4 |
| Reviews | Sub-resource of Places (`/places/{placeType}/{placeId}/reviews`), owned by `StationNetworkModule`/`ThirdPartyPlacesModule` per the polymorphic `Review` entity | ERD §3.15, openapi.yaml |
| Favorites | Sub-resource of `IdentityModule` (`/users/me/favorites`) | openapi.yaml L109–139, ERD §3.16 |
| Search | Query parameters (`q`, `lat`, `lng`, `radiusMeters`) on `GET /places/nearby`, not a module | openapi.yaml L141+ |
| Notifications | `NotificationsModule` | Domain Model §8 |
| Administration | `OperationsModule` (FR-OPS-05 role/site-scope admin) | SRS US-08.5, Module Dependency Diagram §2 |

**This reconciliation was confirmed with the user before any code was written** (see conversation record). Implementation proceeds against the 10 documented bounded-context modules; no module is created that isn't in the Module Dependency Diagram.

## 5. Documentation Gaps Found (flagged, not silently resolved)

- `domain-model.md` (Phase 0) does not list `Review`/`Favorite` as owned entities of any bounded context, though the Phase 1 ERD adds both (`[NEW]`, §3.15/§3.16) as polymorphic over `Station`/`ThirdPartyPlace`. Resolved by inference from the OpenAPI contract's routing (nested under `/places/*` and `/users/me/*`), consistent with `StationNetworkModule`/`ThirdPartyPlacesModule`/`IdentityModule` repository ports.
- `openapi.yaml`'s `BilingualText` schema documents itself as trilingual FR/AR/EN per ADR-0017/"Phase 3 Feature 1", but `User.preferredLanguage` and `UserUpdateRequest.preferredLanguage` remain `enum: [fr, ar]` (no `en`) — consistent with the mobile app's actually-shipped bilingual FR/AR scope (EPIC-06, `docs/epic-06-completion-report.md`). Backend implementation follows the **entity-level enums as authored** (`fr|ar` for user preference) rather than the `BilingualText` doc-comment, since the enum is the binding contract and the mobile client only ever sends `fr`/`ar`. Flagged here rather than unilaterally "fixed" in either document.
- ADR-0016 (hosting) is intentionally `Proposed`, not `Accepted` — irrelevant to writing application code, only to eventual deployment target; not a blocker.
- ADR-0004's time-series engine sub-decision is resolved by ADR-0013 (native Postgres partitioning) — relevant only once `telemetry_reading`/Station Network IoT ingestion is implemented, not for Identity.

## 6. Implementation Order (confirmed)

1. `identity` — authentication (Supabase JWT verification, RBAC guards) — **no dedicated auth endpoints**; Supabase Auth is the identity provider, called directly by clients. The backend's job is verifying Supabase-issued JWTs and enforcing `role`/`site_scope` claims (ADR-0009, Security Architecture §1).
2. `identity` — users, profiles, favorites (`/users/me*`).
3. `station-network` + `third-party-places` — facilities, search, reviews (`/places/*`, `/stations/*`, `/third-party-places/*`).
4. `slatoki`.
5. `notifications`.
6. `operations` — administration (role/site-scope management, alerts, maintenance).

`access-payment`, `emergency`, `sponsorship`, `analytics` are documented bounded contexts not covered by the user's 9-item list — out of scope for this pass, left as scaffold-only until explicitly requested.

## 7. Per-Module Delivery Checklist (applies to every module below)

Domain → DB schema (Prisma) → Validation (class-validator DTOs) → Services (application layer) → Controllers (interface layer) → AuthN → AuthZ → Unit tests → Integration tests → OpenAPI sync (contract-diff against `docs/api/openapi.yaml`) → `npm test` + lint clean → commit. One module (or explicitly-agreed module sub-pass) at a time; no parallel module work.

## 8. First-Time Bootstrap (prerequisite, not a module)

No `package.json`/`tsconfig.json`/Prisma schema/`main.ts` exist anywhere in `apps/backend`. Before Module 1 can run, this pass adds: NestJS project scaffold (TypeScript, `@nestjs/*`, Prisma, class-validator, Jest+Supertest), `prisma/schema.prisma` (datasource + generator + models needed so far), `.env.example`, composition root (`main.ts`, `app.module.ts`), and `platform`/`shared-kernel` cross-cutting code needed by every module (config, structured logging, correlation ID, global `HttpExceptionFilter` per RFC 7807, global `ValidationPipe`). Package manager: `npm` (no ADR specifies one; `npm`/`node` are already available in this environment and no workspace tool is mandated elsewhere in the monorepo) — noted as a judgment call, not a documented requirement.

## 9. Completion Status

| Item | Status |
|---|---|
| All backend ADRs/architecture docs audited | ✅ Complete |
| Current code vs. documentation gap analysis | ✅ Complete — zero application code exists |
| Module-mapping reconciliation (user list vs. documented bounded contexts) | ✅ Complete — confirmed with user |
| Missing modules identified | ✅ Complete — all 10 bounded contexts + 2 cross-cutting modules are unimplemented |
| Implementation order fixed | ✅ Complete |

**Phase 4 kickoff — Implementation Plan: COMPLETE. Proceeding to bootstrap + Module 1 (Identity — Authentication).**

## 10. Status Update — Bootstrap + Module 1 (Identity — Authentication) (2026-08-05)

- Bootstrap: `apps/backend` NestJS/TypeScript/Prisma project scaffolded (`package.json`, `tsconfig*.json`, `nest-cli.json`, ESLint flat config with module-boundary zones, Jest unit + e2e config, `.env.example`, `prisma/schema.prisma`). `npm install` clean; one transient high-severity advisory remains in `@nestjs/swagger`'s `js-yaml` dev-time transitive dependency with no fix available yet (not attacker-reachable from the API surface — no user-supplied YAML parsing route) — tracked, not silently ignored.
- `shared-kernel`: `Money`, `GeoPosition`, `LanguagePreference` VOs, `DomainException` base, base `Repository<T>` port, `DomainEventBus` contract.
- `platform`: `ConfigModule` with fail-fast env validation, `PrismaService`, global RFC 7807 `HttpExceptionFilter`, correlation-ID middleware, Terminus health check (internal, not in `openapi.yaml` — same precedent as the IoT ingestion webhook, api-architecture.md §11).
- `identity` (Pass 1 — Authentication): `Role`/`UserRole`/`User` domain entities + Prisma models (ERD §3.6/§3.7), `SupabaseJwtVerifier` (JWKS or HS256, selected by config), and the full guard stack — `JwtAuthGuard`, `RolesGuard`, `SiteScopeGuard`, `RequireMfaGuard` — wired globally via `APP_GUARD`. No new controllers/OpenAPI surface (ADR-0009: Supabase Auth is the identity provider directly; the backend only verifies its tokens).
- Tests: 51 unit tests + 10 e2e tests, all passing. `tsc --noEmit`, `npm run build`, and `npm run lint` all clean (0 errors; a handful of `no-explicit-any` warnings confined to test mocks).
- Flagged, not silently resolved: user-record provisioning (Supabase Auth user → local `user_account` row on first sight) has no documented mechanism (webhook vs. just-in-time on first `/users/me` request) — carried into Identity Pass 2 as an open item to confirm before implementing `/users/me`.

## 11. Status Update — Identity Pass 2 (Users/Profiles/Favorites) (2026-08-05)

- Resolved the Pass 1 open item as **ADR-0028** (JIT provisioning, `user_account.id = Supabase sub`, atomic no-op-update upsert) — confirmed with the user before implementation.
- Domain: `VerificationDocument` (pending→approved/rejected transition invariant), `PaymentMethod`, `Favorite` (Station-XOR-ThirdPartyPlace invariant, ERD §3.15/§3.16 pattern) entities + Prisma models. `User.id` no longer DB-defaulted (always Supabase `sub`).
- `UserRepository.findOrCreate` — atomic upsert with an empty `update` clause; a unique-constraint violation (email/phone already claimed by a different `id`) is translated to a 409 `ConflictingContactMethodException` rather than leaking a raw Prisma error.
- DB constraints: `@@unique([userId, stationId])` / `@@unique([userId, thirdPartyPlaceId])` on `Favorite` prevent duplicate favorites. The Favorite XOR `CHECK` constraint isn't expressible in Prisma's schema language — documented with exact SQL in `apps/backend/prisma/README.md` for the first real migration; the Domain layer is the enforcement point until then.
- Controllers implementing all of openapi.yaml's `Identity` tag `/users/me*` endpoints: `GET`/`PATCH /users/me` (JIT provisioning), `POST /users/me/verification-documents`, `GET`/`POST /users/me/payment-methods`, `GET`/`POST /users/me/favorites` (cursor-paginated). `openapi.yaml`'s `GET /users/me` description updated to document JIT provisioning.
- No live Postgres is available in this environment (ADR-0016 hosting still Proposed) — `prisma generate` validates the schema; `prisma migrate dev` has not been run against a real database. Concurrency/idempotency behavior is proven at the application layer (in-memory fake repository tests) and at the Prisma-repository-mapping layer (mocked-client tests asserting the upsert shape); true concurrent-request atomicity is a Postgres `ON CONFLICT` guarantee documented in ADR-0028, not independently re-verified here.
- Tests: 82 unit tests + 20 e2e tests (up from 51+10), all passing. `tsc`/build/lint clean.

## 12. Status Update — Facilities (station-network + third-party-places) (2026-08-05)

Implemented in 5 passes per explicit instruction (domain/schema/repos → services/controllers → PostGIS nearby search + composition → reviews/rating → OpenAPI/tests/perf/commit). Two real inconsistencies were found and stopped-on before implementing, both resolved with the user before code was written:

- **ADR-0029 (Places Query Composition)**: `domain-model.md` §3's note ("Station Network exposes a query service consumed by Third-Party Places") directly contradicts `module-dependency-diagram.md`'s CI-enforced matrix and `c4-component.md`'s dependency table (both agree the two contexts have zero dependency on each other). Resolved by adding a narrowly-scoped, read-only composition layer (`src/composition/places/` — `PlacesQueryService`/`PlacesController`, not a bounded-context module) that depends only on each Facilities module's exported `*QueryService`, per the user's explicit requirements: independence preserved, no matrix amendment, writes stay inside their owning module.
- **Architecture violation caught mid-implementation, not by external review**: while wiring `StationDetailController`'s `@Public()` decorator, discovered that Identity Pass 1 had put the cross-cutting AuthN/AuthZ decorators (`@Public`, `@Roles`, `@RequireMfa`, `@CurrentUser`) inside `identity/interface/` — which no other module may import per the matrix. Fixed by relocating them (plus a new `AuthenticatedPrincipal` contract type) to `platform/auth/`, since `PlatformModule` is one of the two modules every other module may depend on. Identity's guards/JWT-verification logic stayed in `identity/`; only the metadata contract moved. Backfilled an ESLint boundary rule (`import/no-restricted-paths`) so no module can make this mistake again.

Domain: `Station` aggregate (Cabin/SlatokiTent), `ThirdPartyPlace`, and — duplicated independently per module, backed by one shared `review` table (ADR-0029's "writes stay in their owning context" extended to Review, since a Review always targets exactly one context) — `StationReview`/`ThirdPartyPlaceReview`. `Station.position`/`ThirdPartyPlace.position` are PostGIS `geography(Point,4326)` columns declared `Unsupported` in Prisma (ADR-0012) and read/written exclusively via `$queryRaw`. `POST /places/{placeType}/{placeId}/reviews` is implemented as two concrete, independent routes (`places/station/:id/reviews` in StationNetworkModule, `places/third-party-place/:id/reviews` in ThirdPartyPlacesModule) rather than one shared dispatching controller — byte-identical URLs to the templated OpenAPI path, zero cross-module coupling.

`GET /places/nearby`'s merge-cursor (composition layer) independently paginates both sources via keyset cursors, merge-sorts by distance, and tracks per-source exhaustion (a dedicated `EXHAUSTED_MARKER`, distinct from "never queried") so a source that's fully drained — including one made permanently empty by a filter combination like `type=rahati_unit` for third-party places — is never re-queried. Covered by dedicated unit tests for every branch (even split, uneven split with leftover, partial-page resumption, untouched-source resumption, full exhaustion).

Two more judgment calls flagged (same treatment as Pass 1/2's `BilingualText`/`preferredLanguage` drift — evidenced from the already-shipped mobile app, not guessed):
- **`name` for places with no ERD name field**: Station has no name column (only `code`) → `name = {fr,ar,en} = code`. ThirdPartyPlace has no `name_en` column → `en` falls back to `name_fr`, mirroring the shipped `LocalizedText.forLanguageCode()` French-fallback convention. Nothing is machine-translated.
- **`pinColor` precedence**: no document defines what happens when a place could match more than one of the four RAH-DOC-002 functional colors. Derived from `place_marker.dart`'s shipped color/icon semantics: Slatoki (magenta) takes priority; a station with a mixed or empty cabin set falls back to the generic "RAHETI unit" (amber) bucket since a single free/paid boolean can't represent it.

Performance: `station.status`, `cabin.occupancy_status`, `third_party_place.place_type`, `review.station_id`/`review.third_party_place_id` indexes added directly to `schema.prisma`. The ERD's `idx_station_position`/`idx_place_position` GIST indexes cannot be Prisma-managed (same `Unsupported`-column limitation as the geography columns themselves) — documented with exact SQL in `apps/backend/prisma/README.md` for the first real migration. No live Postgres exists in this environment (ADR-0016 still Proposed) to run `EXPLAIN ANALYZE` against — flagged, not fabricated; rating aggregation is computed inline in the same query as the nearby search (pre-grouped CTEs to avoid a cabin×review join fan-out) specifically to avoid N+1 round trips, the one performance property verifiable without a live database.

OpenAPI: implementation matches `docs/api/openapi.yaml`'s `Places` tag exactly (`PlaceSummary`/`StationDetail`/`ThirdPartyPlaceDetail`/`Cabin`/`SlatokiTent`/`Review`/`ReviewCreateRequest` schemas, `/places/nearby`/`/stations/{id}`/`/stations/{id}/cabins`/`/third-party-places/{id}`/`/places/{placeType}/{placeId}/reviews` paths); no contract changes were needed.

Tests: 168 unit tests + 35 e2e tests (up from 82+20). `tsc`/build/lint clean (0 errors).

**Facilities module: code/design complete, verified, documented. Ready to commit.**

## 13. Status Update — Slatoki (2026-08-05)

Before Pass 1, flagged and resolved a direct conflict between the instruction ("keep Slatoki independent, no cross-context dependencies") and the documented architecture: `domain-model.md` §4 and `module-dependency-diagram.md` §3 both explicitly grant Slatoki — and only Slatoki — sanctioned read-only edges to **both** `StationNetwork` and `ThirdPartyPlaces` (`Slatoki -.->|read| StationNetwork/ThirdPartyPlaces`), because Slatoki owns no data of its own: it is "a presentation-and-filtering concern over two existing data sources... not a new physical entity with its own lifecycle." Without that read access, `FR-SLK-03/04/05` and `GET /slatoki/places` are impossible to implement (there is no independent Slatoki data store) and Qibla calculation is explicitly client-side-only. Confirmed with the user: implement exactly as documented — no owned aggregate/persisted state/Prisma model/repository, dependency limited strictly to `StationQueryService`'s and `ThirdPartyPlaceQueryService`'s exported surface (never their domain/infrastructure/interface layers), all writes stay in their owning module (Slatoki has none).

Domain: `PrayerFacilityFilter`/`WomenVerificationLevel` VOs, `QiblaDirectionCalculator` (great-circle bearing to the Kaaba) — implemented for architectural completeness with `domain-model.md` §4's documented ownership, deliberately not wired to any controller (openapi.yaml is explicit that Qibla bearing is client-side-only). Extended `StationPlaceSearchItem` (Facilities, already-committed code) with a direct `hasSlatokiTent` field so Slatoki's qualification logic doesn't have to reverse-infer tent presence from `pinColor === 'magenta'` — a small, justified touch of already-shipped code rather than a fragile cross-module coupling to another module's presentation-color derivation.

Business rules (FR-SLK-04, evidenced from RAH-DOC-005 §2.3's exact wording, not guessed): a Station qualifies for Slatoki only when it has a deployed-tent-capable `SlatokiTent` and is always `verified_confirmed` (RAHETI-operated, not a self-declared claim); a ThirdPartyPlace qualifies only when tagged `prayer` and/or `wudu`, and is `verified_confirmed` only when additionally tagged `women_confirmed` — otherwise shown as `generic`, not excluded, per FR-SLK-04's "distinguish... from" (both classes are shown). The `prayer_only`/`wudu_only`/`prayer_and_wudu` filter (FR-SLK-03) is a capability check ("supports at least what was asked for"), not an exact match — flagged judgment call, semantics aren't specified beyond the three enum values. FR-SLK-05 (tent deployment status/capacity/amenities) needed no new work — already fully satisfied by Facilities' `StationDetailDto.slatokiTent`.

OpenAPI: `GET /slatoki/places` (openapi.yaml) has no `radiusMeters`/`cursor`/`limit` parameters at all, unlike `/places/nearby` — implemented with no client-configurable pagination/radius, matching the contract exactly rather than adding parameters it doesn't define. Internal fixed radius/result-cap values are a flagged judgment call (openapi.yaml specifies none). `SlatokiPlaceSummary` schema matched exactly.

Performance: no new Prisma queries, indexes, or database access at all — Slatoki reuses Facilities' already-indexed `searchNearby` queries verbatim through their exported services.

Tests: 186 unit tests (up from 168) + 41 e2e tests (up from 35). `tsc`/build/lint clean (0 errors).

**Slatoki module: code/design complete, verified, documented. Ready to commit.**
