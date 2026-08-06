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

## 14. Status Update — Notifications (2026-08-05)

Implemented in 5 passes per explicit instruction (domain/schema/repos → services/controllers/validation/auth → preferences/read-unread/delivery channels → event integration/localization/perf/retry → OpenAPI/tests/lint/build/commit). One real inconsistency was found and stopped-on before implementing, resolved with the user before code was written:

- **Missing read/unread state**: `domain-model.md` §8 and `docs/api/openapi.yaml`'s `Notification` schema have no field for a client to observe read/unread state at all, even though `PATCH /users/me/notifications/{notificationId}` is documented as "Mark a notification as read" — there is nothing for that mutation to be idempotent *against*. Resolved by the user as an additive schema gap-fill (not an architectural change): `is_read BOOLEAN NOT NULL DEFAULT false` / `read_at TIMESTAMP NULL`, exposed as `isRead`/`readAt` on every `Notification` response, `PATCH` sets `isRead = true` and `readAt` exactly once and stays idempotent on repeat calls, unread notifications always have `readAt = null`. A DB `CHECK` constraint enforcing that consistency is documented in `apps/backend/prisma/README.md` (same "hand-written migration, no live DB yet" treatment as the Favorite/Review XOR constraints) alongside the domain-level invariant already enforced in `Notification.restore()`/`markAsRead()`.

Domain: `Notification` aggregate (`queue()`/`restore()`/`markAsRead()` idempotent/`markSent()`/`markDelivered()`/`markFailed()` state machine — `queued → sent → delivered`, `queued|sent → failed`, invalid transitions throw `InvalidNotificationStatusTransitionException`). `userId` is nullable (`onDelete: SetNull`) for role-targeted notifications (e.g. `operator_alert`) with no single recipient. `relatedAlertId`/`relatedTransactionId` are intentionally dangling string references, not Prisma relations — `Alert`/`Transaction` don't exist yet (Operations/AccessPayment out of scope) — documented in the schema's own comments, not silently modeled as FKs to nothing.

Kept as a genuinely independent bounded context per the instruction: owns its own `Notification` table outright (unlike Slatoki, which owns nothing), and the only sanctioned dependency used is `IdentityModule`'s exported `UserQueryService` (recipient-language resolution for copy localization) — the one read edge `module-dependency-diagram.md` §3 grants Notifications. No other module may import `notifications/` (backfilled as an ESLint `import/no-restricted-paths` zone, same enforcement pattern as every prior module).

Delivery: `NotificationSender` port (`infrastructure/channels/`, not `domain/ports/` — precedent drawn from `repository-structure.md`'s `access-payment/infrastructure/payment-gateway/` PaymentGateway port, ADR-0014) with `InAppNotificationSender` (always succeeds, no-op) and `PushNotificationSender` (always throws `PushNotificationNotConfiguredException` — no FCM/APNs credentials or device-token storage exist anywhere in the ERD, flagged rather than fabricated). `NotificationDeliveryService` retries up to 3 attempts with exponential backoff (200ms, 400ms) before marking `failed`; `sent`+`delivered` are set together on success since neither sender has a separate asynchronous delivery-confirmation step to observe. Copy is resolved natively per notification type in French and Arabic (`NotificationCopyResolver`), consistent with the shipped app's bilingual convention used throughout Facilities/Slatoki.

Event integration: `shared-kernel`'s `DomainEventBus` was missing its documented `subscribe()` method (README described pub/sub, interface only had `publish`/`publishAll`) — fixed directly as a bootstrap oversight, not a new architecture decision, same treatment as the `platform/auth` relocation and `IdentityModule` export fixes from earlier modules. Added a concrete `InProcessEventBus` (in-process only, no external broker — "no infrastructure beyond current project scope") in `platform/events/`. `NotificationEventSubscriber` subscribes only to a consumer-defined `PaymentCapturedEvent` — `CabinOccupancyChanged`/`AlertRaised` are deliberately not wired this pass since no cross-module "who to notify" query exists anywhere and their publishing modules (StationNetwork's occupancy-write-path, Operations) don't exist yet either.

Performance: `notification.userId` is indexed (added directly in Prisma schema, Pass 1) for `GET /users/me/notifications`'s per-user list query — no PostGIS/geography columns involved, no GIST-index gap to defer.

OpenAPI: added `isRead`/`readAt` to the `Notification` schema (per the confirmed gap-fill) and a `404` response reference to `PATCH /users/me/notifications/{notificationId}` (matches `NotificationService.markAsRead`'s actual behavior — the same `NotificationNotFoundException` is thrown for "doesn't exist" and "belongs to a different user," deliberately not distinguished, to avoid leaking existence of another user's notification).

Tests: 235 unit tests (up from 186) + 47 e2e tests (up from 41). `tsc`/build/lint clean (0 errors, pre-existing `no-explicit-any` warnings only).

**Notifications module: code/design complete, verified, documented. Ready to commit.**

## 15. Status Update — Operations (2026-08-05)

Final module of this pass's confirmed 6-item implementation order (§6). Implemented `Alert`/`MaintenanceIntervention` (own aggregates, Domain Model §10), fleet-wide station view (FR-OPS-01), and telemetry-backed occupancy history (FR-OPS-04, ADR-0013) against `docs/api/openapi.yaml`'s `Operations` tag exactly (`GET`/`PATCH /ops/alerts*`, `GET`/`POST /ops/maintenance-interventions`, `GET /ops/stations`, `GET /ops/stations/{id}/occupancy-history`). FR-OPS-05 needed no new endpoint at all — already satisfied by Identity Pass 1's `Role`/`UserRole` entities and globally-wired `RolesGuard`/`SiteScopeGuard` (same "needed no new work" precedent as Slatoki's FR-SLK-05).

Extended `StationNetworkModule` (not a new architecture decision — the sanctioned `Ops -> StationNet` edge, module-dependency-diagram.md §3, plain ✔) with `StationRepository.findAll()` and `StationQueryService.listAllForFleetView()`, returning a plain projection (not the `Station`/`Cabin` domain entities) so Operations never imports station-network/domain — same pattern `StationPlaceSearchItem` already established for Slatoki.

Three real gaps were found and flagged (not silently resolved), consistent with every prior module's treatment of a documentation gap:

- **`site_scope`-based filtering cannot be implemented.** `GET /ops/stations`'s openapi.yaml description says "scoped by site_scope," and ERD §3.7 defines `user_role.site_scope`, but no ERD entity or `schema.prisma` model defines a `Site` concept or a `station.site_id`/`site` column for that scope to filter against. `SiteScopeGuard` (identity module) only compares against a literal `:siteId` route parameter, which none of the `/ops/*` routes have. `GET /ops/stations` and `GET /ops/alerts` return the full, unscoped fleet/alert set — flagged rather than inventing a `Site` entity not in the ERD. Resolving this needs a Site/multi-tenancy design decision outside this pass's scope.
- **`telemetry_reading` has no bounded-context owner in `domain-model.md`** (none of the 10 documented contexts list it as an owned entity) **and no ingestion write path exists.** Modeled under Operations because its only documented consumer endpoint (`GET /ops/stations/{id}/occupancy-history`) is tagged `Operations` and ADR-0013 ties it directly to FR-OPS-04. Ingestion is Station Network's telemetry Anti-Corruption Layer per the Domain Model §1 context map, fed by the IoT Platform — Master Roadmap Phase 9, entirely out of scope (not merely deferred, unlike Access & Payment/Emergency/Sponsorship/Analytics). The read-side query and schema are real and unit-tested against a mocked Prisma client; the table itself will stay empty until Phase 9, same treatment as Facilities' PostGIS queries validated with no live database.
- **ADR-0013's native declarative range partitioning isn't expressible in Prisma's schema language** — documented in `apps/backend/prisma/README.md` for the first real migration, same treatment as the existing GIST spatial indexes.

Two judgment calls (same treatment as every prior module's flagged, evidence-grounded decisions):
- **Alert/MaintenanceIntervention status-transition graphs**: neither the ERD, `domain-model.md`, nor `openapi.yaml` specify the full transition graph beyond the enum values and `AlertUpdateRequest`'s allowed targets. Alert requires acknowledgement before any further transition (`open -> acknowledged -> {in_progress, resolved}`); MaintenanceIntervention allows `scheduled/in_progress -> cancelled` alongside the natural `scheduled -> in_progress -> completed` path. Both flagged inline in the entity source.
- **`MaintenanceInterventionCreateRequest.assignedTo`** is optional in openapi.yaml but NOT NULL in ERD §3.12 — reconciled by defaulting to the scheduling operator (JWT `sub`) when omitted, rather than relaxing the DB constraint or inventing a new nullable-assignee concept.

Tests: 277 unit tests (up from 235, includes 2 new `station-network` tests for `findAll`/`listAllForFleetView`) + 61 e2e tests (up from 47). `tsc`/build/lint clean (0 errors, pre-existing `no-explicit-any` warnings only).

**Operations module: code/design complete, verified, documented. Committed (`472d77e`).**

## 16. Phase 4 Completion

All 6 items of this pass's confirmed implementation order (§6) are now complete: Identity (Authentication, Users/Profiles/Favorites), Station Network + Third-Party Places (Facilities), Slatoki, Notifications, and Operations. `access-payment`, `emergency`, `sponsorship`, `analytics` remain scaffold-only, exactly as scoped in §6 — out of scope for this pass, not silently dropped.

**Phase 4 Implementation Plan: COMPLETE per this document's own confirmed scope.** See `docs/phase-4-completion-report.md` for the full completion report, architecture summary, and recommended next phase.

## 17. Status Update — Access & Payment (2026-08-06)

First out-of-original-scope module built after §16's "Phase 4 Complete" milestone — `AccessPaymentModule` (Domain Model §6, EPIC-04, V1-critical), implementing the QR-scan-to-unlock journey and its transactional payment record (`docs/api/openapi.yaml`'s `AccessPayment` tag: `POST`/`GET /access-sessions`, `POST /access-sessions/{id}/payments`, `POST /access-sessions/{id}/complete`).

Domain: `AccessSession` (`initiate() -> {payment_pending, unlocked, cancelled}`, transition graph per Domain Model §6's one stated invariant — "UnlockOrderIssued may only follow either a free-cabin AccessSessionInitiated or a PaymentCaptured — never precede payment for a paid cabin") and `Transaction` (separate aggregate, `pending -> authorized -> captured -> refunded`, `-> failed` from either of the first two) as two independent aggregate roots, mirroring Operations' `Alert`/`MaintenanceIntervention` precedent for "separate aggregates, one optionally referencing the other." `QrCode` VO encodes a V1 judgment call, flagged rather than silently assumed: neither the ERD, `domain-model.md`, nor `openapi.yaml` specify the QR payload's encoding, so the payload is treated as the target cabin's UUID directly, with no separate lookup table.

Extended `StationNetworkModule` with the sanctioned `AccessPay -> StationNet` **command** dependency (module-dependency-diagram.md §3, plain ✔ — distinct from every other module's `✔(read)` edge, since cabin availability must be checked and occupancy written synchronously): a new `StationCommandService` (`checkCabinAvailability`/`setCabinOccupancy`), `Cabin.changeOccupancy()` mutator (the entity's `props` were made mutable, same "mutable domain entity" precedent as Operations' `Alert`), and two additive `StationRepository` port methods (`findCabinById`/`updateCabinOccupancy`).

Two ADR-scale gaps were found and resolved, both flagged rather than silently decided:

- **No IoT unlock-dispatch implementation exists anywhere** (Phase 9, 0 files) — the QR-scan-to-unlock sequence (Sequence Diagrams §1) assumes an IoT ingestion service/MQTT broker that doesn't exist, and Risk R-11/R-12's refund-on-unlock-failure path is the module's single most important edge case. Resolved via **[ADR-0030](../adr/0030-lock-control-abstraction.md)**: a `LockControlGateway` port + deterministic `MockLockControlAdapter`, exactly mirroring [ADR-0014](../adr/0014-payment-provider-abstraction.md)'s already-accepted `PaymentGateway` precedent — R-12's refund path is fully tested today (unit + e2e), not merely "architected."
- **`applyEmergencyDiscount` (`PaymentRequest.applyEmergencyDiscount`, FR-EMG-03's 50% Mode Urgence discount) cannot be computed this pass.** Eligibility requires reading the caller's `diabeticVerificationStatus` from Identity's `User` aggregate, and `module-dependency-diagram.md` §3 grants `AccessPay` no read edge to `Identity` at all (unlike e.g. `Emergency -.->|read| Identity`). The flag is accepted (never rejected) and silently ignored — a documented, explicit V1 gap in `AuthorizeAndCapturePaymentService`'s own doc comment, not a bug and not an invented cross-module dependency outside the matrix.

Idempotency (`api-architecture.md` §8, R-11/R-12): a new `IdempotencyKey` model (additive gap-fill, not in the ERD — same "confirmed" treatment as Notification's `is_read`/`read_at`) and a shared `IdempotencyService` used by both `InitiateAccessSessionService` and `AuthorizeAndCapturePaymentService`, deduping on `(userId, key, endpoint)`. On a cache hit, the service replays via a fresh repository re-fetch (not a byte-for-byte snapshot of the original response) — domain entities aren't directly JSON-serializable by their private-constructor/`props` shape, and a fresh `findById` accurately reflects the unchanged, still-current persisted state within the same short idempotency window.

Rate limiting (`api-architecture.md` §9): a hand-rolled, in-memory token-bucket `RateLimitGuard` (`platform/http/`, no new npm dependency per the explicit constraint), applied via `@RateLimit(10, 60_000)` — a placeholder threshold, same "explicitly provisional, tune later" treatment as ADR-0026's 30-second client-side unlock timeout — only to `POST /access-sessions` and `POST /access-sessions/{id}/payments`, keyed on `(caller, route)` so the two decorated routes don't share one combined bucket.

Two contract-drift judgment calls, both resolved in the DTO's favor without changing the documented OpenAPI contract:

- **Free-cabin payment response.** `openapi.yaml`'s `Transaction` schema declares no `required` fields at all, so `TransactionResponseDto.fromDomain(transaction: Transaction | null, session)` legitimately omits `id`/`amount`/`discountApplied`/`status` for the free-cabin case (`transaction === null`, per Domain Model §6: "a free-access session produces no transaction row") — no OpenAPI change was needed.
- **`UNLOCK_FAILED_REFUNDED` reused for the free-cabin unlock-failure case too**, even though nothing was actually captured/refunded there — the sequence diagram's failure branch sits after the paid/free split rejoins, with no separate free-cabin failure code documented; reusing the one documented code was judged more consistent than inventing a second, undocumented one.

Migration: `migrations/20260806121959_access_payment/` was initially **generated but not applied live** during implementation — a normal `prisma migrate dev` hit pre-existing extension-metadata drift and proposed a destructive `prisma migrate reset`, which the implementation pass was not authorized to run. Generated instead via `prisma migrate diff --from-schema-datasource ... --to-schema-datamodel ...` (introspects the live DB directly, no shadow database needed) and hand-edited to remove two false-positive `DROP INDEX` statements the diff engine proposed against the first migration's hand-added GIST indexes. Full detail in `apps/backend/prisma/README.md`'s new "Access & Payment module" section. During the subsequent implementation review, the migration was applied via `prisma migrate deploy` and independently verified live against the local Supabase Postgres instance (`prisma migrate status`: "Database schema is up to date!"; `psql \d access_session`/`\d transaction`/`\d idempotency_key` confirmed correct columns/FKs/indexes; both pre-existing GIST indexes confirmed intact).

Tests: 392 unit tests (up from 277) + 76 e2e tests (up from 61), independently re-run during review. `tsc`/build clean; lint 0 errors (23 warnings, up from the prior 20-warning baseline — the 3 new ones are `no-explicit-any` in the new Prisma-repo `.spec.ts` files, the same pattern every other Prisma-repo spec file in this codebase already has).

**Access & Payment module: code/design complete, independently reviewed, migration applied and verified live. Committed following review approval.**

## 18. Status Update — Emergency (EPIC-03, Mode Urgence) (2026-08-06)

Second out-of-original-scope module built after §16's "Phase 4 Complete" milestone — `EmergencyModule` (Domain Model §7, EPIC-03, V1.1), implementing `GET /emergency/nearest-facility` (FR-EMG-01/02/03). No owned aggregate, no Prisma models — pure orchestration, same category as Slatoki, depending only on Identity's and Station Network's exported query services (the matrix's `Emergency -.->|read| Identity`/`Emergency -.->|read| StationNetwork` edges).

Extended `StationNetworkModule` with `StationQueryService.findNearestAccessible()` (new Prisma query: nearest `active`-status station within a flagged 20km judgment-call radius, `EMERGENCY_SEARCH_RADIUS_METERS`; a flagged cabin-tiebreak rule — prefer `free`, else any non-`out_of_service`, else `null` — neither specified anywhere in FR-EMG-02/ERD/OpenAPI).

Closed a gap Access & Payment's own code had already flagged: `AuthorizeAndCapturePaymentService`'s `applyEmergencyDiscount` was a documented V1 no-op pending Emergency Mode's existence. **ADR-0031** grants `AccessPaymentModule` a new `AccessPay -.->|read| Identity` edge (mirroring the pre-existing `Notif -.->|read| Identity` edge) so the discount is independently re-verified server-side against `diabeticVerificationStatus`, never trusted from the client's boolean alone — deliberately hardening beyond the literal sequence-diagram, since this gates a real monetary amount. `AccessPaymentModule` does **not** get an edge to `EmergencyModule` — the matrix still grants Emergency no incoming edges from any module (enforced by a new eslint zone); the two modules independently apply the same FR-EMG-03 invariant rather than one depending on the other. New `Money.applyDiscountPercentage()` (shared-kernel, bigint-safe) backs the actual amount reduction, applied consistently through authorize/capture/refund.

**Inherited, accepted, out-of-scope limitation, not addressed by this pass** (mirrors R-02/ADR-0014's precedent before Access & Payment exactly): Risk R-01 (diabetic-verification mechanism undefined, score 16, still open) means no real user can currently reach `diabeticVerificationStatus = verified` — `VerificationDocumentService` only implements document submission, with no admin-approval workflow (explicitly deferred by ADR-0010 to an unscheduled health-partner workshop). Emergency Mode is built completely and correctly against the already-existing enum; its discount-eligible branch is only reachable via seeded dev/test data until that separate, unscoped workflow exists.

No Prisma migration — Emergency owns no data, confirmed before implementation began.

Tests: 423 unit tests (up from 392) + 83 e2e tests (up from 76), independently re-run during review. `tsc`/build clean; lint 0 errors (27 warnings, up from 23 — the 4 new ones are `no-explicit-any` in new test files, same pre-existing pattern).

**Emergency module: code/design complete, independently reviewed. Committed following review approval.**
