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
