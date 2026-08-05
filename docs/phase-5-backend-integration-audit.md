# Phase 5 — Backend Integration Audit

| | |
|---|---|
| **Document ID** | RAH-DOC-045-PHASE-5-INTEGRATION-AUDIT |
| **Phase** | Phase 5 — Flutter App (backend integration sub-pass) |
| **Version** | 1.0 |
| **Status** | Complete — audit only, no code modified |
| **Date** | 2026-08-05 |
| **Baseline** | Backend @ commit `dd61470` (Phase 4 complete) · Mobile app @ current working tree |

## 0. Method and a correction to the task's framing

This audit reads `apps/mobile/lib` directly (every `Mock*`/`Fake*`/`Rest*`/`Supabase*` repository, every `*RemoteDataSource`, every DTO, every provider wiring file) and cross-checks each REST call against `docs/api/openapi.yaml` and the actual NestJS controllers built in Phase 4. No guessing: every endpoint path, field name, and auth requirement cited below is quoted from a specific file.

**Important correction, found during the audit, that changes the shape of the work:** the mobile app is *not* wired to mocks by default. Every mock/real swap point (`authRepositoryProvider`, `userRepositoryProvider`, `favoriteRepositoryProvider`, `placeDetailRepositoryProvider`, `reviewRepositoryProvider`, `paymentRepositoryProvider`) already defaults to its `Rest*`/`Supabase*` implementation — the `Mock*` classes are opt-in only, behind `--dart-define` flags (`USE_MOCK_AUTH`, `USE_MOCK_PLACE_DETAIL`, `USE_MOCK_PAYMENT`) that all default to `false` (`lib/core/constants/env.dart`). This was built under ADR-0023's explicit-mock-adapter pattern specifically so the real code path could exist and be demoed before a backend existed.

So "replace mocks with the real backend" is, architecturally, **already done** for most features. What actually blocks the app from working against the real backend now is:
1. **No request anywhere attaches a Supabase JWT.** Confirmed by grepping the entire `lib/` tree for `Authorization`/`Bearer`/`access_token` — zero matches outside unrelated `AuthorizationResult` payment-domain naming. Every `*RemoteDataSource` independently builds its own `http` call with, at most, a `Content-Type` header. Every non-public backend route (everything except the 5 listed in §2) requires `JwtAuthGuard` (wired globally in `identity.module.ts`) and will return 401. This is a single, shared, cross-cutting gap — not a per-feature one — because every data source pulls its `http.Client` from one shared provider (`httpClientProvider`, `place_providers.dart:20`).
2. A handful of **real, specific contract mismatches** found feature-by-feature (§3–§4).
3. **Two features that were never built at all** on the mobile side — Notifications (no repository, no inbox screen; `notification_settings_screen.dart` is local-only `State`, explicitly documented as such) and Visit History (`RestVisitHistoryRepository` always throws `VisitHistoryEndpointNotSpecifiedFailure` — there is no backend endpoint for it in `openapi.yaml` either). Building either now would be a **new feature**, which this turn's instructions explicitly rule out. Both are flagged, not silently built.

Given this, §5's migration order is revised from "swap mock → real, feature by feature" to: **fix the one shared prerequisite first, then verify/fix each feature's already-real wiring in the requested order**, skipping any step that would require inventing an endpoint the backend doesn't have.

## 1. Mock / Fake / Stub / Demo Inventory

| Class | File | Used by (provider) | Default active? |
|---|---|---|---|
| `MockAuthRepository` | `profile/data/repositories/mock_auth_repository.dart` | `authRepositoryProvider` (`auth_providers.dart`) | No — `USE_MOCK_AUTH=true` only |
| `MockUserRepository` | `profile/data/repositories/mock_user_repository.dart` | `userRepositoryProvider` | No — `USE_MOCK_AUTH=true` only |
| `MockFavoriteRepository` | `profile/data/repositories/mock_favorite_repository.dart` | `favoriteRepositoryProvider` (`profile_providers.dart`) | No — `USE_MOCK_AUTH=true` only |
| `MockVisitHistoryRepository` | `profile/data/repositories/mock_visit_history_repository.dart` | `visitHistoryRepositoryProvider` | No — `USE_MOCK_AUTH=true` only (real path always throws — no endpoint exists) |
| `MockPlaceDetailRepository` | `map_discovery/data/repositories/mock_place_detail_repository.dart` | `placeDetailRepositoryProvider` (`place_detail_providers.dart`) | No — `USE_MOCK_PLACE_DETAIL=true` only |
| `MockReviewRepository` | `map_discovery/data/repositories/mock_review_repository.dart` | `reviewRepositoryProvider` | No — `USE_MOCK_AUTH=true` only |
| `MockCabinRealtimeRepository` | `map_discovery/data/repositories/mock_cabin_realtime_repository.dart` | `cabinRealtimeRepositoryProvider` | No — reuses `USE_MOCK_PLACE_DETAIL=true` |
| `MockPaymentRepository` | `access_payment/data/repositories/mock_payment_repository.dart` | `paymentRepositoryProvider` (`payment_providers.dart`) | No — `USE_MOCK_PAYMENT=true` only |
| `MockPaymentMethodRepository` | `access_payment/data/repositories/mock_payment_method_repository.dart` | `paymentMethodRepositoryProvider` | No — `USE_MOCK_PAYMENT=true` only |
| `MockPaymentGatewayAdapter` | `access_payment/data/adapters/mock_payment_gateway_adapter.dart` | `paymentGatewayProvider` | **Yes, unconditionally** — ADR-0014 mandates this until a real payment provider is selected; not a stand-in for a missing backend call |

No `Stub*`/`Demo*`-named classes exist. Out of scope for this audit (Payment/Access-Payment wasn't in the requested feature list, and the backend's `access-payment` module is scaffold-only — 0 source files, per the Phase 4 audit) but flagged for completeness: `MockPaymentRepository`/`MockPaymentMethodRepository`'s `Rest*` counterparts call endpoints (`/v1/access-sessions*`, `/v1/users/me/payment-methods`) that literally don't exist on the backend yet.

## 2. Backend Endpoint Reference (Phase 4, confirmed built)

Public (`security: []`, no JWT required) — 5 total: `GET /places/nearby`, `GET /stations/{stationId}`, `GET /stations/{stationId}/cabins`, `GET /third-party-places/{placeId}`, `GET /slatoki/places`. Every other route requires a Bearer JWT (`JwtAuthGuard`, wired globally).

## 3. Repository → Endpoint Map (verified against openapi.yaml + actual controllers)

| Flutter repository | Backend endpoint | Auth required | Contract status |
|---|---|---|---|
| `SupabaseAuthRepository` | Supabase Auth directly (no RAHATI backend route — ADR-0009: "no dedicated auth endpoints") | N/A (Supabase, not this backend) | ✅ Correct by design |
| `RestUserRepository` → `UserRemoteDataSource` | `GET /v1/users/me` | Yes | ⚠️ Field mapping correct (`AppUserDto` = `User` schema exactly); **no Authorization header sent** |
| `RestFavoriteRepository` → `FavoriteRemoteDataSource` | `GET`/`POST /v1/users/me/favorites` | Yes | ⚠️ Field mapping correct; **no Authorization header**; **ignores `nextCursor`** (backend paginates, client reads `data` only — will silently truncate past the first page); `removeFavorite`/`setNotifyOnAvailable` correctly documented as impossible (`DELETE`/`PATCH` never existed in the contract — real, permanent API gap, not a client bug) |
| `RestPlaceDetailRepository` → `PlaceDetailRemoteDataSource` | `GET /v1/stations/{id}`, `GET /v1/third-party-places/{id}` | No (public) | ✅ Correct — `StationDetailDto`/`ThirdPartyPlaceDetailDto` match `StationDetail`/`ThirdPartyPlaceDetail` schemas field-for-field, including the `allOf: [PlaceSummary, {...}]` flattening |
| `RestPlaceRepository` → `PlaceRemoteDataSource` | `GET /v1/places/nearby` | No (public) | ✅ Correct mapping (`PlaceDto` = `PlaceSummary` exactly, including GeoJSON `[lng,lat]` order); only sends `lat`/`lng`/`radiusMeters` — `type[]`/`q`/`cursor` deliberately omitted per ADR-0021 (client-side filtering over one fetch, explicitly documented as upgradeable later, not a bug) |
| `RestReviewRepository` → `ReviewRemoteDataSource` | `POST /v1/places/{placeType}/{placeId}/reviews` | Yes | ⚠️ Field mapping correct (`rating`/`comment` in, `ReviewDto` = `Review` schema out); **no Authorization header**; `getMyReviews`/`updateReview`/`deleteReview` correctly documented as impossible (no such endpoints exist) |
| `RestSlatokiPlaceRepository` → `SlatokiPlaceRemoteDataSource` | `GET /v1/slatoki/places` | No (public) | ✅ Correct — `SlatokiPlaceDto` = `SlatokiPlaceSummary` exactly |
| *(none — no repository exists)* | `GET /v1/users/me/notifications`, `PATCH /v1/users/me/notifications/{id}` | Yes | ❌ Not integrated — no Flutter data layer for Notifications exists at all (confirmed: no repository, no DTO, no remote data source; `notification_settings_screen.dart` explicitly documents this itself). **Building it is a new feature — out of scope this turn.** |
| `RestVisitHistoryRepository` | *(no backend endpoint — always throws)* | N/A | ❌ Real, permanent gap on the backend side (not this session's scope — `access-payment`/history isn't a built module) |
| — | Any `/ops/*` endpoint | Yes (`operateur` role + MFA) | N/A — no operator-facing screen exists anywhere in `app_router.dart`; **Operations integration is not required by this app** |

## 4. Integration Plan by Feature

### Prerequisite (blocks every authenticated feature below) — Authenticated HTTP client
- **Current data source**: each `*RemoteDataSource` independently calls `ref.watch(httpClientProvider)`, a single shared `Provider<http.Client>` defined once in `place_providers.dart:20` and reused by every other feature's providers.
- **Target**: every protected endpoint in §2/§3.
- **Required change**: wrap the shared client in one new `AuthenticatedHttpClient extends http.BaseClient` that reads `supabaseClientProvider`'s current session (`_client.auth.currentSession?.accessToken`) and attaches `Authorization: Bearer <token>` to every outgoing request before delegating to the real `http.Client`. Swap `httpClientProvider`'s body to construct this wrapper instead of a bare `http.Client()`. **This is the only place this needs to change** — no `*RemoteDataSource` file needs touching, since they all already depend on `httpClientProvider` indirectly, not `http.Client()` directly.
- **Risk**: low technically (one file), but it's a shared dependency — a mistake here breaks every feature at once, not just one. Must be verified against both a signed-in and guest (no session) state, since public endpoints must keep working with no header at all.

### 1. Authentication
- **Current data source**: `SupabaseAuthRepository` (real, direct Supabase Auth calls) — already the default whenever `AppEnv.isSupabaseConfigured`; no RAHATI backend involvement by design (ADR-0009).
- **Target backend endpoint**: none — confirmed correct as-is.
- **DTO changes**: none.
- **Repository changes**: none.
- **Provider changes**: none required for Auth itself. `currentUserIdProvider`/`currentUserProvider` already correctly chain into `UserRepository` once signed in.
- **UI changes**: none.
- **Risks**: none found. The only action item is environment configuration (`SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY` at build time), not code.

### 2. User Profile
- **Current data source**: `RestUserRepository` (already default).
- **Target backend endpoint**: `GET /v1/users/me` (confirmed implemented, JIT-provisions the user row per ADR-0028).
- **DTO changes**: none — `AppUserDto` already matches the `User` schema exactly.
- **Repository changes**: none beyond the shared auth-header fix above.
- **Provider changes**: none.
- **UI changes**: none.
- **Risks**: first-request JIT provisioning (ADR-0028) means the very first `GET /users/me` after sign-up does an implicit upsert — verify this doesn't race with a second concurrent call (e.g. Favorites resolving a place detail at the same moment). Also flag: **Visit History (SCR-021)** is part of the Profile area in the UI but has no backend support at all — `RestVisitHistoryRepository` will always throw; this is a pre-existing, correctly-documented gap, not something to fix this pass.

### 3. Favorites
- **Current data source**: `RestFavoriteRepository` (already default).
- **Target backend endpoint**: `GET`/`POST /v1/users/me/favorites`.
- **DTO changes**: none for field mapping. Recommend (not required to unblock): read `nextCursor` from the list response so favorites beyond the first page aren't silently dropped — currently `FavoriteRemoteDataSource.getFavorites()` discards it.
- **Repository changes**: shared auth-header fix. Optionally extend `getFavorites()` to page through `nextCursor`.
- **Provider changes**: none.
- **UI changes**: none required; `removeFavorite`/`setNotifyOnAvailable` already correctly show as unavailable (no such backend endpoint) — do not attempt to "fix" this, it's a real contract gap, not a client bug.
- **Risks**: `RestFavoriteRepository.getFavorites()` calls back into `PlaceDetailRepository` per favorite to resolve `placeName`/position (N calls for N favorites) — verify this doesn't visibly stall the Favorites screen once real network latency (vs. instant mocks) is in play.

### 4. Facilities (station/third-party-place detail)
- **Current data source**: `RestPlaceDetailRepository` (already default; public endpoints, no auth-header fix needed here).
- **Target backend endpoint**: `GET /v1/stations/{id}`, `GET /v1/third-party-places/{id}`.
- **DTO changes**: none — verified field-exact.
- **Repository changes**: none.
- **Provider changes**: none.
- **UI changes**: none.
- **Risks**: lowest-risk feature in this plan — already public, already default, already contract-verified. Main risk is simply confirming it end-to-end once a real database has real rows (Phase 4's own completion report already flags: no live Postgres has ever been exercised).

### 5. Nearby Search
- **Current data source**: `RestPlaceRepository` (was **always** real — no mock ever existed for this one; `place_local_data_source.dart`/`AppDatabase` provide the offline cache per ADR-0008/ADR-0022, which is a separate, legitimate concern from mocking).
- **Target backend endpoint**: `GET /v1/places/nearby`.
- **DTO changes**: none — verified field-exact, including GeoJSON coordinate order.
- **Repository changes**: none required. Optional future work (not this pass): send `type[]`/`q`/`cursor` server-side instead of client-side filtering — ADR-0021 already anticipates this as a minimal data-layer-only change.
- **Provider changes**: none.
- **UI changes**: none.
- **Risks**: public endpoint, no auth-header dependency — can be verified independently of the prerequisite fix. Main risk is the offline-cache fallback path (`isFromCache`) behaving correctly against real (vs. simulated) network failures.

### 6. Reviews
- **Current data source**: `RestReviewRepository` (already default).
- **Target backend endpoint**: `POST /v1/places/{placeType}/{placeId}/reviews`.
- **DTO changes**: none — verified field-exact.
- **Repository changes**: shared auth-header fix only.
- **Provider changes**: none.
- **UI changes**: none; `getMyReviews`/`updateReview`/`deleteReview` correctly show as unavailable (SCR-023's "My Reviews" screen has no listing endpoint — confirmed absent from openapi.yaml).
- **Risks**: `placeType`'s wire value (`station`/`third-party-place`, hyphenated) is mapped explicitly and correctly in `RestReviewRepository` — verify this exact string against the live route once tested (a silent case/hyphenation mismatch would 404, not 401, so it wouldn't be caught by the auth-header fix's own testing).

### 7. Slatoki
- **Current data source**: `RestSlatokiPlaceRepository` (already default; public endpoint).
- **Target backend endpoint**: `GET /v1/slatoki/places`.
- **DTO changes**: none — verified field-exact.
- **Repository changes**: none.
- **Provider changes**: none.
- **UI changes**: none.
- **Risks**: lowest-risk alongside Facilities — public, already default, contract-verified. Qibla bearing is correctly client-side-only per the contract (no server dependency to verify there).

### 8. Notifications
- **Current data source**: none. No repository, DTO, remote data source, or inbox screen exists anywhere in `apps/mobile/lib`. `notification_settings_screen.dart` is a local-only, unpersisted `State` (its own doc comment explains why: no preferences endpoint exists in `openapi.yaml`, only the inbox endpoints).
- **Target backend endpoint**: `GET /v1/users/me/notifications`, `PATCH /v1/users/me/notifications/{id}` (confirmed built, Phase 4).
- **Required work**: a full new feature module (domain entity, DTO, remote data source, repository, provider, an inbox screen — SCR-028/EPIC-10 was never designed or built). **This is new-feature work, explicitly out of scope for this turn's instructions ("Do not implement new features").**
- **Recommendation**: do not build this in the mock-replacement pass. Flag it as a distinct, separately-scoped feature request for the user to explicitly greenlight, the same way Phase 4's Operations module gaps were flagged rather than silently built.

### 9. Operations
- **Current data source**: N/A.
- **Target backend endpoint**: `/ops/*` (confirmed built, Phase 4).
- **Required work**: none. No operator-facing screen exists in this app (`app_router.dart` has zero `/ops`-area routes) — RAHATI's mobile app is the end-user (`usager`) surface; Operations serves the separate Operator Dashboard (`apps/operator-dashboard/`, currently a placeholder `README.md` only, no code). **Not required by this app**, confirmed rather than assumed.

## 5. Migration Order (app stays runnable at every step)

1. **Prerequisite**: `AuthenticatedHttpClient` behind `httpClientProvider` — a single, isolated, easily-revertible change. Verify public endpoints (Facilities, Nearby Search, Slatoki) still work with no session, and that a signed-in session now sends a header, before touching anything feature-specific.
2. **Authentication** — no code change expected; verify only.
3. **User Profile** — verify `GET /users/me` now succeeds end-to-end with the header attached.
4. **Favorites** — verify list/add; optionally add cursor pagination.
5. **Facilities** — verify only (already correct, unaffected by the auth fix).
6. **Nearby Search** — verify only (already correct, unaffected by the auth fix).
7. **Reviews** — verify submit now succeeds with the header attached.
8. **Slatoki** — verify only (already correct, unaffected by the auth fix).
9. **Notifications** — **excluded this pass** (new feature, needs explicit scoping/approval first).

This order matches the one given in the task, with the addition of the shared prerequisite at the front (nothing downstream can be honestly verified against a live, non-public backend route without it) and Notifications called out as excluded rather than silently skipped.

## 6. Recommendation

Per this turn's instruction to deliver the audit before touching code: **pausing here.** Two things are worth confirming before I start:

1. **The prerequisite fix** (§4, `AuthenticatedHttpClient`) isn't literally "replacing a mock" — it's a small addition to shared infrastructure that every subsequent feature step depends on. Confirming this is in scope before I touch `httpClientProvider`.
2. **Notifications** cannot be completed as "replace the mock" (there is no mock, or any prior implementation, to replace) without building a new feature, which conflicts with this turn's explicit instruction. Confirming you want it dropped from this pass (§4 §8) rather than built.

No backend to test against exists yet either (Phase 4's own completion report: ADR-0016 hosting still Proposed, no live Supabase project or deployed API — same caveat applies here). "Verified" below and in every subsequent commit means: contract-checked against `openapi.yaml` and the actual controller source, and covered by `flutter analyze`/`flutter test`/widget-level integration tests using a fake `http.Client` — not a live end-to-end run against a running backend, which isn't possible in this environment yet.

## 7. Decisions Confirmed (2026-08-05)

Both questions in §6 were confirmed with the user before further code changed:

1. **Prerequisite approved and implemented** — `AuthenticatedHttpClient` (`lib/core/network/authenticated_http_client.dart`), wired at the single `httpClientProvider` swap point (`place_providers.dart`), attaching `Authorization: Bearer <token>` to every request via a token-getter closure sourced from `GoTrueClient.currentSession`. No repository/data source changed; no auth logic duplicated. `flutter analyze` clean, `flutter test` 532/532 passing (up from 527). Committed `c664d9f`.
2. **Notifications confirmed excluded** from this Phase 5 integration pass — explicitly a backend-integration phase, not a feature-development one. No `NotificationRepository`, DTO, provider, or UI will be created here. Remains tracked as a future, separately-scoped integration item (§4 §8 of this document) once explicitly requested.

Proceeding to §5's migration order: Authentication → User Profile → Favorites → Facilities → Nearby Search → Reviews → Slatoki, one feature at a time, each verified (`flutter analyze` + `flutter test` + integration tests) and committed before the next starts.
