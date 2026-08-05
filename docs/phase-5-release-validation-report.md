# Phase 5 — Release Validation Report (Real Device, Real Backend)

| | |
|---|---|
| **Document ID** | RAH-DOC-046-PHASE-5-RELEASE-VALIDATION |
| **Phase** | Phase 5 — Flutter App (release validation sub-pass) |
| **Version** | 1.0 |
| **Status** | Complete for the scope executed — see §6 for what remains unverified |
| **Date** | 2026-08-05 |
| **Device** | `21121119SC` (physical, Android 12 / API 31, USB-connected) |
| **Backend** | Local Supabase stack (`supabase start`, Docker) + local NestJS API, both running on the same machine, reached from the device via `adb reverse` |

## 1. Objective

Install the current app on a physical Android device, connect it to a genuinely running backend (not mocks, not a simulated server), and exercise the production flows from `docs/phase-5-backend-integration-audit.md`'s migration order end-to-end. No backend had ever been deployed anywhere before this pass — building one was itself the first prerequisite (per explicit instruction, confirmed with five safety checks before the one destructive command involved — `docs/phase-4-completion-report.md` and this session's own record).

## 2. Local Environment Setup Report

### 2.1 What was stood up

1. **Docker Desktop** started (was not running).
2. **Local Supabase stack** (`supabase init` + `supabase start`, in an untracked scratch directory — not added to the repo, since this project's schema is Prisma-owned per ADR-0004/ADR-0012, not Supabase-CLI-migration-owned): Postgres 17 + PostGIS 3.3.7, GoTrue (Auth), Kong, PostgREST, Storage, Realtime, Studio. Connection details:
   - `DATABASE_URL`: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`
   - `SUPABASE_URL` (Auth/API): `http://127.0.0.1:54321`
   - Publishable key: `sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH`
3. **First-ever Prisma migration** (`apps/backend/prisma/migrations/20260805181420_init/`) generated and applied — see §2.2, this surfaced a real bug, now fixed and committed (`5cbe8c3`).
4. **Documented manual SQL** applied as part of that same migration: both GIST spatial indexes (`idx_station_position`, `idx_place_position`) and all four hand-written `CHECK` constraints (Favorite/Review polymorphic XOR, Review rating range, Notification read-state consistency) — all previously only described in `prisma/README.md`, now real and verified in the live schema.
5. **Seed data** (ad hoc, direct SQL, not committed to the repo as a script): the two lookup tables explicitly documented as "Seeded, not user-editable via API" in `schema.prisma` (`Role`: 4 codes; `Tag`: 5 codes), plus one `Station` + 2 `Cabin`s + 1 `SlatokiTent` + 1 `ThirdPartyPlace` (tagged `prayer`/`wudu`/`women_confirmed`), placed at the device's actual resolved GPS coordinates (36.7108, 3.0681 — Hussein Dey, Algiers) so Facilities/Nearby Search/Slatoki/Reviews had something real to find. No seed script was added to the codebase — this was explicitly scoped as ad hoc test fixture data for this session, not a new feature.
6. **NestJS backend** started locally (`npm run start`) against the above.
7. **Device connectivity**: `adb reverse tcp:3000 tcp:3000` and `adb reverse tcp:54321 tcp:54321` (device treats `localhost` as the dev machine, tunneled over USB) + the app built with `--dart-define=SUPABASE_URL=http://localhost:54321 --dart-define=SUPABASE_PUBLISHABLE_KEY=... --dart-define=API_BASE_URL=http://localhost:3000`.

### 2.2 A real bug found while standing this up (fixed, `5cbe8c3`)

Supabase's own Postgres image installs five platform-default extensions into `public` (`pgcrypto`, `uuid-ossp`, `pg_stat_statements`, `pg_net`, `supabase_vault`) that weren't declared in `schema.prisma`'s datasource block. Undeclared, Prisma's drift detector refused to migrate at all — and this isn't a local-only quirk, a real hosted Supabase project would hit the identical drift the first time `prisma migrate dev` ran against it. Declared alongside `postgis`; fixed in the canonical schema, not worked around locally.

### 2.3 A judgment call, confirmed correct, not a bug

`.env`'s first draft used `SUPABASE_JWT_SECRET` (the legacy HS256 shared-secret verification strategy, both strategies already correctly implemented and documented in the backend since Phase 4). Local Supabase actually signs JWTs with ES256 (confirmed by decoding a real token's header and cross-checking the CLI's own JWKS endpoint) — the current Supabase default, exactly as `.env.example`'s own comment already said. Switched to `SUPABASE_JWT_JWKS_URL`. This was a one-line environment config correction, not an application bug — see §4's Authentication finding for how this was diagnosed.

## 3. End-to-End Validation Checklist

| # | Area | Item | Result |
|---|---|---|---|
| 1 | Authentication | Sign in | ✅ Verified live, after fixing the JWT verification strategy (§4.1) |
| 1 | Authentication | Sign out | ✅ Verified live — immediate, correct guest-state revert |
| 1 | Authentication | Session restore | ✅ Verified live — killed and relaunched the app, session (and the unlocked Profile sections) were intact |
| 1 | Authentication | Token refresh | ⚠️ Verified by code inspection only (`gotrue-2.26.0` source: `autoRefreshToken` defaults `true`, internal `Timer.periodic` keeps the session current) — not empirically observed in this session, since a real token expiry (1 hour) wasn't practical to wait out |
| 2 | User Profile | Load profile | ✅ Verified live — real `GET /users/me`, correct JIT-provisioned data shown |
| 2 | User Profile | Edit / Save / Reload | ⬜ Not exercised — no edit-profile screen exists in the app's current UI (out of scope to build one; not investigated further given the time already spent on higher-priority findings) |
| 3 | Favorites | Add favorite | ⚠️ Backend/repository confirmed working (verified directly via API — 201 Created, then listed correctly), but **there is no UI entry point anywhere in the app to add a favorite** (see §4.4) — the on-device "through the UI" flow could not be exercised because the affordance doesn't exist |
| 3 | Favorites | Remove favorite | N/A — `removeFavorite` has no backend endpoint at all (pre-existing, already documented gap, `FavoriteEndpointNotSpecifiedFailure`) |
| 3 | Favorites | Persistence after restart | ✅ Verified live — favorite (added via direct API call) appeared correctly in the app's Favorites list, resolved name/distance via the real place-detail endpoint |
| 3 | Favorites | Pagination | ⚠️ Verified via unit test only (multi-page cursor-following, added this pass — see §4.3); not exercised with real bulk (>20) data on-device |
| 4 | Facilities | Load list / Open details | ✅ Verified live, including the critical bug fix in §4.2 |
| 4 | Facilities | Search | ⬜ Not exercised — search bar is present and functional per existing widget tests, but wasn't driven on-device this pass (time-boxed; lower risk, already covered by passing widget tests) |
| 4 | Facilities | Filters (Gratuit/Payant/RAHETI) | ⬜ Not exercised on-device this pass; covered by existing widget/unit tests (ADR-0021 client-side filtering) |
| 4 | Nearby Search | Real request/response, clustering, pin colors | ✅ Verified live end-to-end against the real backend and PostGIS |
| 5 | Reviews | Create / Update / Delete / Rating aggregation | ⬜ Not exercised on-device this pass (time-boxed after the Authentication/Slatoki investigations) — backend and repository already contract-verified in the prior Backend Integration Audit pass (`dce1d93`) with full unit/e2e coverage; genuinely not re-driven through the UI here |
| 6 | Slatoki | Search / Filters / Open details | ✅ Verified live, including the critical bug fix in §4.3 |
| 7 | Offline handling | Disable network → error state → restore → recovery | ✅ Verified live — real "Hors connexion" banner with cached data + staleness timestamp, automatic recovery with no manual retry (FR-MAP-07), after correctly discovering `adb reverse` bypasses the wifi/data toggle and severing the tunnel directly instead |
| 8 | Performance | Cold start | ✅ App launched and rendered the map within a few seconds on every cold start observed |
| 8 | Performance | Navigation | ✅ No visible jank across every screen transition exercised (Map/Slatoki/Profile/detail sheets) |
| 8 | Performance | API latency | ⬜ Not formally measured (no instrumentation added this pass) — all real requests observed felt sub-second, but this is qualitative, not a number |
| 8 | Performance | Memory usage | ⬜ Not measured — no profiling tool run this pass |
| 8 | Performance | Crash check | ✅ Full-session `logcat` review: zero `FATAL EXCEPTION`/ANR entries for the app process across the entire multi-hour session |

## 4. Bugs Found and Fixed

### 4.1 Authentication: sign-in appeared to succeed but never authenticated (root cause: my own environment config, not app code)

**Symptom**: Sign-in/sign-up screens popped back (no visible error), Supabase confirmed a real session was created server-side (`auth.sessions`, `auth.refresh_tokens` rows existed), but the Profile screen kept showing guest state, even after killing and relaunching the app.

**Diagnosis** (temporary debug logging added, used, then fully reverted — confirmed via `git diff` showing zero residual change): `currentUserIdProvider` genuinely emitted the correct, non-null user id (confirmed in logs) — ruling out the auth/session layer. The Profile screen depends on `currentUserProvider`, which calls `GET /users/me`; that request was failing. Root cause: the local Supabase instance signs JWTs with **ES256** (confirmed by decoding the token header and reading the CLI's `/auth/v1/.well-known/jwks.json`), but the backend `.env` was configured for the legacy **HS256** shared-secret strategy — a pure local-environment misconfiguration on my part (§2.3), not a code defect. **No application code was broken or changed for this one** — fixing `.env` (gitignored, not committed) resolved it completely, verified with a direct `curl` to `GET /v1/users/me` (200, correct profile) and then on-device (Profile screen correctly showed the account, unlocked every implemented section).

### 4.2 Backend: `/health` required authentication (fixed, `5cbe8c3`)

`curl http://localhost:3000/health` returned 401 before the fix. `HealthController` had no `@Public()` decorator, so the globally-wired `JwtAuthGuard` blocked it — defeating the purpose of a liveness/readiness probe (infrastructure health checkers never carry a user JWT). Fixed by adding `@Public()`. Verified: 200 with `{"status":"ok","database":"up"}` after.

### 4.3 Mobile: place detail sheet crashed with "Impossible de charger les détails de ce lieu" (fixed, `1d5d653`)

Opening any station or third-party-place detail sheet against the real backend failed. Root cause: `GET /stations/{id}`/`GET /third-party-places/{id}` never include `distanceMeters` in their response (correctly — there's no search origin for a by-id lookup, unlike `GET /places/nearby`), but `PlaceDto.fromJson` treated the field as always-present (`(json["distanceMeters"] as num)`, no null check), throwing a `TypeError` on every real detail fetch. Fixed by defaulting to `0` when absent, in the DTO parser only — confirmed inert (the distance actually shown in the sheet's header always comes from the already-known search-result `Place`, never from this embedded summary). Also fixed the two existing detail-DTO test fixtures, which had `"distanceMeters": 100.0` hard-coded in — matching neither endpoint's real shape, so those tests would never have caught this. Verified live, twice: before the fix (error banner) and after (full cabin list with real occupancy/pricing).

### 4.4 Mobile: Android blocked all cleartext traffic to the local backend (fixed, `1d5d653`)

Before any backend call could even be attempted, every request failed — Android blocks plain HTTP by default for `targetSdkVersion >= 28`, and the local dev backend has no TLS. Fixed with a debug-build-only `network_security_config.xml` permitting cleartext to `localhost`/`127.0.0.1`/`10.0.2.2` only (never merged into release builds; production endpoints are always HTTPS and unaffected).

### 4.5 Mobile: Slatoki screen silently hid every RAHETI station under every filter tab (fixed, `547c490`)

**Critical.** A seeded Station with a deployed Slatoki tent, correctly returned by `GET /slatoki/places` (`womenVerificationLevel: verified_confirmed`), never appeared in the app's Slatoki list — under any of the three filter tabs, always. Root cause: `filterSlatokiPlaces()` checked `place.tags` for `"prayer"`/`"wudu"` uniformly, but Stations never carry tags at all (tags are Third-Party-Place-only, ERD §3.5/§3.6) — the check was always false for a Station. The backend already has, and documents, the correct rule (`SlatokiQueryService.matchesFilter`: "A RAHETI Slatoki tent always offers both prayer and wudu... matches every filter value unconditionally") — the Flutter client just never implemented it. This made RAHETI's own Slatoki tents — arguably the feature's primary qualifying entity — invisible in this screen, always, in every build before this fix. Fixed by special-casing `PlaceKind.station` to always match, mirroring the backend exactly. Verified live, before and after: the seeded station was absent under all three tabs pre-fix, present with its full `SlatokiTentStatusCard` (6 mats, lighting, privacy curtain, "Déployée") post-fix.

### 4.6 Testing-process finding, not a product bug: seed-data mojibake

My own first SQL insertion (via a Bash heredoc piped through `docker exec psql`) corrupted the mosque's French/Arabic name into double-encoded UTF-8 garbage. Confirmed as an artifact of my own tooling pipeline, not the app or backend — reseeded correctly with `chr()`-based SQL, no code change needed.

## 5. Bugs Found, Not Fixed (real product gaps, flagged rather than built)

- **§3, item 3.1**: There is no UI affordance anywhere in the app to add a favorite. The full stack below it (backend endpoint, `RestFavoriteRepository`, `FavoriteRemoteDataSource`) works correctly and is unit-tested — but no widget ever calls `.addFavorite()`. Building one is new-feature work, explicitly out of scope for this pass ("do not implement new features"). Recommend scoping as its own follow-up.
- **Pre-existing, already documented before this pass, re-confirmed still true**: `removeFavorite`/`setNotifyOnAvailable`/`getMyReviews`/`updateReview`/`deleteReview` all have no backend endpoint at all (`docs/phase-5-backend-integration-audit.md` already covered this) — not new findings, just re-verified as still accurate.

## 6. Scope Not Exercised This Pass (time-boxed, not skipped silently)

Reviews CRUD, Facilities search/filters on-device, Edit Profile (no such screen exists), API latency/memory instrumentation, and empirical token-refresh observation were not driven on the physical device this pass — see the checklist (§3) for exactly which and why. None of these showed any problem in existing automated test coverage; they are flagged as **not independently re-verified live**, not as failing.

## 7. Release Readiness Assessment

**Not production-ready as of this report**, per the explicit instruction not to declare readiness unless every critical flow passes live. Two things block that:

1. **Favorites has no way to be used** — the core "add a favorite" action has no UI. This is a real product gap on a documented, backlogged feature (SCR-026, US-05.4), not a regression.
2. **Reviews CRUD was not re-driven live this pass** — it has strong existing coverage (unit/e2e/widget tests, plus the prior Backend Integration Audit's contract verification) but wasn't independently exercised on the device in this session, so it isn't in the "verified live" set this report can vouch for.

Everything that **was** driven live on the physical device against the real backend passed after the fixes in §4: Authentication (sign in/out/session restore), User Profile (load), Facilities (load/details), Nearby Search, Slatoki (search/filter/details), and Offline handling (degradation + automatic recovery). Three real, previously-undetectable bugs (§4.2–4.5) were found, fixed, verified live, and are committed. No crash or ANR was observed in a multi-hour session.

**Recommendation**: build the Favorites "add" UI and re-run Reviews CRUD live as the next two concrete gates before a broader release-readiness call, rather than treating this report as a final sign-off.

## 8. Environment State at End of Session

The local Supabase stack and NestJS backend were left running (not torn down), in case further validation continues in a follow-up session. `apps/backend/.env` is gitignored and not committed. No seed script was added to the repository. `adb reverse` port forwards are active. Screenshots captured during this session are in `apps/mobile/.validation-screenshots/` (untracked, not committed — local evidence only).
