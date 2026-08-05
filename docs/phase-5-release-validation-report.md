# Release Validation Report

| | |
|---|---|
| **Document ID** | RAH-DOC-046 |
| **Phase** | Phase 5 — Flutter App (release validation sub-pass) |
| **Version** | 2.0 (restructured to the required section set; supersedes v1.0's ad hoc structure — no factual content removed) |
| **Status** | Final |
| **Date** | 2026-08-05 |
| **Scope** | Real physical Android device, connected to a real (locally hosted) Supabase + NestJS backend — no mocks |

This report documents the first, and to date only, end-to-end validation pass of the RAHATI Flutter app running against a genuinely running backend on a physical device. It is evidence-based throughout: every claim below is either something directly observed this session, or is explicitly marked **Not verified**.

## 1. Test Environment

| Item | Value |
|---|---|
| Host OS | Windows 11 |
| Container runtime | Docker Desktop |
| Backend runtime | Node.js, NestJS (`npm run start`), local process |
| Database | PostgreSQL 17 + PostGIS 3.3.7 (Supabase's official local image) |
| Auth provider | GoTrue (Supabase Auth), local instance |
| Device↔host bridge | `adb reverse tcp:3000 tcp:3000`, `adb reverse tcp:54321 tcp:54321` (USB) |
| Backend/device connectivity | This was a **local development environment**, not a hosted/production deployment. No hosted Supabase project exists (ADR-0016 status remains "Proposed" — see RAH-DOC-048 §Database). |

## 2. Backend Environment

- **Stack**: local Supabase CLI stack (`supabase init` + `supabase start`) — Postgres 17 + PostGIS, GoTrue, Kong, PostgREST, Storage, Realtime, Studio — plus the project's own NestJS API run separately against it.
- **Connection**: `DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres`, `SUPABASE_URL=http://127.0.0.1:54321`.
- **Schema**: first-ever real Prisma migration applied — `apps/backend/prisma/migrations/20260805181420_init/migration.sql` (commit `5cbe8c3`), 18 application tables, 2 GIST spatial indexes (`idx_station_position`, `idx_place_position`), 4 hand-written `CHECK` constraints (Favorite/Review polymorphic XOR, review rating range, notification read-state consistency) — all previously documented as intended in `prisma/README.md`, now verified as real and enforced in a live database for the first time.
- **JWT verification**: local Supabase signs with ES256 by default; backend configured via `SUPABASE_JWT_JWKS_URL` (JWKS strategy), not the legacy HS256 shared-secret strategy — confirmed correct by decoding a real issued token's header and cross-checking the CLI's own `/auth/v1/.well-known/jwks.json`.
- **Seed data**: ad hoc, not committed to the repository — `Role` (4 codes) and `Tag` (5 codes) lookup rows plus one `Station` + 2 `Cabin`s + 1 `SlatokiTent` + 1 `ThirdPartyPlace`, placed at the device's real resolved GPS coordinates (36.7108, 3.0681, Hussein Dey, Algiers).
- **Backend code state during this pass**: identical to what is committed at `bd8cff2` (no application code changes were made specifically to accommodate the local environment — only `apps/backend/.env`, which is gitignored and not committed, and the canonical `schema.prisma` extension fix in `5cbe8c3`, which applies to any Supabase project, local or hosted).

## 3. Flutter Environment

| Item | Value |
|---|---|
| Build | Debug build (`flutter run` / `flutter build apk --debug`) |
| Build flags | `--dart-define=SUPABASE_URL=http://localhost:54321 --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH --dart-define=API_BASE_URL=http://localhost:3000` |
| Cleartext traffic | Enabled only for this build via a **debug-build-only** `network_security_config.xml` (`apps/mobile/android/app/src/debug/`), scoped to `localhost`/`127.0.0.1`/`10.0.2.2`; not present in release builds |
| App code state | Identical to what is committed at `bd8cff2` |

**Not verified**: a release-mode build was not exercised on-device this pass (see RAH-DOC-048 §Android Release for why a real release build cannot currently be produced — debug signing only).

## 4. Device Information

| Item | Value |
|---|---|
| Device ID | `21121119SC` |
| Type | Physical Android device (not an emulator) |
| Android version | Android 12 (API 31) |
| Connection | USB, `adb` |
| GPS | Real device location services, resolved to 36.7108, 3.0681 (Hussein Dey, Algiers) |

## 5. Executed Test Scenarios and Results

| # | Area | Scenario | Result |
|---|---|---|---|
| 1 | Authentication | Sign in | ✅ Verified live, after fixing a local JWT verification config (§7, Environment Notes) |
| 1 | Authentication | Sign out | ✅ Verified live — immediate, correct guest-state revert |
| 1 | Authentication | Session restore after app kill/relaunch | ✅ Verified live |
| 1 | Authentication | Token refresh | ⚠️ Verified by source-code inspection only (`gotrue-2.26.0`: `autoRefreshToken` defaults `true`, internal periodic timer) — **not empirically observed**; a real token expiry (1 hour) was not waited out |
| 2 | User Profile | Load profile (`GET /users/me`) | ✅ Verified live — correct JIT-provisioned data shown |
| 2 | User Profile | Edit / save / reload | ⬜ Not exercised — no edit-profile screen exists in the app's current UI |
| 3 | Favorites | Add favorite | ⚠️ Backend confirmed working via direct API call (201 Created, then correctly listed) — **no UI entry point exists anywhere in the app**, so the flow could not be exercised as an end user would |
| 3 | Favorites | Remove favorite | N/A — no backend endpoint exists for this action (pre-existing, documented gap) |
| 3 | Favorites | Persistence after restart | ✅ Verified live (favorite added via direct API call, then correctly rendered by the app with real name/distance) |
| 3 | Favorites | Pagination (multi-page cursor) | ⚠️ Verified via unit test only this pass; not exercised with real bulk (>20) data on-device |
| 4 | Facilities | Load list / open details | ✅ Verified live, including the crash fix in §6.3 |
| 4 | Facilities | Search | ⬜ Not exercised on-device; covered by existing widget tests only |
| 4 | Facilities | Filters (Gratuit/Payant/RAHETI) | ⬜ Not exercised on-device; covered by existing widget/unit tests only |
| 4 | Nearby Search | Real request/response, clustering, pin colors | ✅ Verified live end-to-end against PostGIS |
| 5 | Reviews | Create / update / delete / rating aggregation | ⬜ **Not exercised on-device this pass.** Covered by unit/e2e/widget tests and the prior Backend Integration Audit's contract verification (commit `dce1d93`), but not independently re-driven live here |
| 6 | Slatoki | Search / filters / open details | ✅ Verified live, including the critical bug fix in §6.4 |
| 7 | Offline handling | Disable network → error state → restore → automatic recovery | ✅ Verified live, including correctly discovering that `adb reverse` bypasses the wifi/data toggle (worked around by removing the port forward directly) |
| 8 | Performance | Cold start | ✅ App rendered the map within a few seconds on every observed cold start |
| 8 | Performance | Navigation jank | ✅ No visible jank across every screen transition exercised |
| 8 | Performance | API latency | ⬜ **Not formally measured** — no instrumentation added this pass; all requests observed felt sub-second, qualitative only |
| 8 | Performance | Memory usage | ⬜ **Not measured** — no profiling tool run this pass |
| 8 | Performance | Crash/ANR check | ✅ Full-session `logcat` review: zero `FATAL EXCEPTION`/ANR entries across a multi-hour session |

## 6. Bugs Found and Fixed

### 6.1 Backend: `/health` required authentication (fixed, `5cbe8c3`)
`curl http://localhost:3000/health` returned 401. `HealthController` lacked `@Public()`, so the global `JwtAuthGuard` blocked it. Fixed by adding `@Public()`. Verified: 200 `{"status":"ok","database":"up"}` after.

### 6.2 Backend: Prisma schema missing Supabase's default extensions (fixed, `5cbe8c3`)
Supabase's Postgres image installs `pgcrypto`, `uuid-ossp`, `pg_stat_statements`, `pg_net`, `supabase_vault` by default; undeclared in `schema.prisma`, Prisma's drift detector refused to migrate. This is a canonical fix applicable to any Supabase project (local or hosted), not a local-only workaround — declared alongside the pre-existing `postgis` extension.

### 6.3 Mobile: place-detail sheet crashed on real data (fixed, `1d5d653`)
`GET /stations/{id}` and `GET /third-party-places/{id}` never include `distanceMeters` (no search origin for a by-id lookup), but `PlaceDto.fromJson` cast it as non-nullable, throwing on every real detail fetch. Fixed with a null-coalescing default. Two existing test fixtures had incorrectly hard-coded this field, meaning tests would never have caught the bug — both fixed.

### 6.4 Mobile: Android blocked all cleartext traffic to the local backend (fixed, `1d5d653`)
`targetSdkVersion >= 28` blocks plain HTTP by default. Fixed with a debug-build-only `network_security_config.xml` scoped to `localhost`/`127.0.0.1`/`10.0.2.2`; not present in release builds, production endpoints are HTTPS.

### 6.5 Mobile: Slatoki screen hid every RAHETI station under every filter tab (fixed, `547c490`) — **Critical**
A seeded Station with a deployed Slatoki tent, correctly returned by the backend (`womenVerificationLevel: verified_confirmed`), never appeared in the app's Slatoki list under any filter tab. Root cause: `filterSlatokiPlaces()` checked `place.tags`, but Stations never carry tags (tags are Third-Party-Place-only, ERD §3.5/§3.6) — the check was always false. The backend already implements and documents the correct rule (`SlatokiQueryService.matchesFilter`: a Station always matches every filter); the Flutter client had never implemented the mirror of that rule. This made RAHATI's own Slatoki tents invisible in this screen in every build before this fix. Fixed by special-casing `PlaceKind.station`. Verified live before/after.

## 7. Environment Notes (not application bugs)

- **Authentication initially appeared broken**: sign-in/session created server-side but the Profile screen kept showing guest state. Diagnosed (via temporary debug logging, added and fully reverted) to a local `.env` misconfiguration — HS256 shared-secret strategy configured, but local Supabase signs with ES256. Fixed by switching to `SUPABASE_JWT_JWKS_URL`. No application code was changed for this; `.env` is gitignored and not committed.
- **Seed-data mojibake**: a Bash-heredoc SQL insertion corrupted French/Arabic text encoding — an artifact of the seeding tooling used this session, not a product defect; reseeded correctly.

## 8. Performance Observations

- Cold start, navigation transitions: qualitatively smooth, no observed jank, across every screen exercised.
- **API latency: Not verified** — no timing instrumentation was added; no numeric measurement exists.
- **Memory usage: Not verified** — no profiler was attached this pass.
- **Load/concurrency behavior: Not verified** — this was a single-user, single-device session against a local single-instance backend.

## 9. Stability Observations

- Zero crashes or ANRs observed across a multi-hour on-device session (`adb logcat` reviewed in full for the app's process).
- Offline-to-online recovery was automatic and correct (FR-MAP-07): no manual retry needed after connectivity was restored.
- Three application-level bugs were found and fixed during this pass (§6.3–6.5); all three were regressions that had **zero prior live-backend testing to catch them** — every prior test run in this project's history (unit/widget/e2e) used mocked or in-memory data, so none of the three bugs were, or could have been, caught before this pass.

## 10. Security Observations

- JWT verification (JWKS/ES256) confirmed working correctly end-to-end against a real Auth provider.
- Debug-only cleartext allowance is correctly scoped to debug builds only (`apps/mobile/android/app/src/debug/`) and does not affect release builds or production endpoints.
- **Not verified in this pass** (see RAH-DOC-048 §Security for full detail): rate limiting (confirmed absent from the codebase, not merely untested), Row-Level Security policy enforcement (no live database with RLS applied has ever existed), production TLS/certificate behavior (no hosted deployment exists), dependency vulnerability scanning.

## 11. Known Limitations

See **RAH-DOC-047 (Known Issues Register)** for the complete, severity-ranked list. The limitations most directly evidenced by this validation pass:

- Favorites has no "add" UI entry point anywhere in the app (KI-003).
- Reviews CRUD was not independently re-driven live this pass (KI-007).
- No profile-editing UI exists (KI-008).
- Token refresh, API latency, and memory usage were not empirically measured (KI-010, KI-013).
- This pass validated a **local development environment only** — no hosted/production backend has ever been exercised (KI-001).

## 12. Final Conclusion

This was the first, and to date only, validation of the RAHATI Flutter app against a real, running backend (not mocks) on a physical Android device. It found and fixed three real, previously-undetectable defects (§6.3–6.5), one of which (§6.5) was critical — it hid RAHATI's own qualifying stations from the Slatoki feature entirely, in every build prior to this fix, and had never been exercised against real backend data before. Every scenario in §5 marked ✅ passed as observed; every scenario marked ⚠️ or ⬜ is explicitly flagged, not silently assumed to pass.

**This report does not declare the application production-ready.** Two concrete gaps prevent that conclusion: Favorites has no usable "add" affordance (a core, documented feature that cannot currently be exercised by an end user at all), and Reviews CRUD — while covered by strong automated test coverage — was not re-verified live in this pass. Both are catalogued with severity, impact, and planned resolution in RAH-DOC-047. A full production-readiness evaluation across all 13 standard readiness areas is in RAH-DOC-048.

## 13. Environment State at End of Session

The local Supabase stack and NestJS backend were left running for potential follow-up. `apps/backend/.env` is gitignored, not committed. No seed script was added to the repository. `adb reverse` port forwards were active at session end. Screenshots captured are in `apps/mobile/.validation-screenshots/` (untracked, not committed).
