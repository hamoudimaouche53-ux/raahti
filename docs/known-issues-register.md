# Known Issues Register

| | |
|---|---|
| **Document ID** | RAH-DOC-047 |
| **Version** | 1.0 |
| **Status** | Final |
| **Date** | 2026-08-05 |
| **Source** | RAH-DOC-044 (Phase 4 Completion Report), RAH-DOC-045 (Phase 5 Backend Integration Audit), RAH-DOC-046 (Release Validation Report), direct repository inspection (commit `bd8cff2`) |

Every entry below is evidenced by a specific, cited source. Sorted **Critical → High → Medium → Low**. "Status" reflects whether the issue is Open (unaddressed), Deferred (intentionally out of scope for a documented reason), or Accepted (a known, permanent trade-off).

## Critical

### KI-001 — No production backend/database deployment exists
- **Severity**: Critical
- **Description**: No hosted Supabase project, and no hosted instance of the NestJS backend, has ever been created. ADR-0016 (hosting provider selection) status is "Proposed (indicative shortlist) — final provider approval required before Phase 3," not Accepted. All validation to date (RAH-DOC-046) ran against a local-only Supabase + NestJS stack.
- **Impact**: The application cannot serve real end users in any environment; there is no production system to deploy the app against.
- **Workaround**: None — this is a prerequisite, not a bug.
- **Planned milestone**: Master Roadmap Phase 3 (hosting/infrastructure) — precedes any real deployment.
- **Status**: Open

### KI-002 — Android release build uses debug signing, not a production keystore
- **Severity**: Critical
- **Description**: `apps/mobile/android/app/build.gradle.kts`, `release` block: `signingConfig = signingConfigs.getByName("debug")`. No release keystore or signing configuration exists anywhere in the repository.
- **Impact**: The app cannot be published to the Google Play Store or distributed as a trusted release build in its current state.
- **Workaround**: None for real distribution; debug-signed APKs can still be sideloaded for internal testing (as done in RAH-DOC-046).
- **Planned milestone**: Prior to any Alpha/Beta distribution — required before Master Roadmap's Android release milestone.
- **Status**: Open

## High

### KI-003 — Favorites has no "add" UI anywhere in the app
- **Severity**: High
- **Description**: The backend endpoint, `RestFavoriteRepository`, and `FavoriteRemoteDataSource` all work correctly (confirmed via direct API call, RAH-DOC-046 §5, row "Favorites / Add favorite") and are unit-tested, but no widget in the app calls `.addFavorite()`. There is no UI affordance to trigger it.
- **Impact**: A documented, core feature (SCR-026, US-05.4) is completely unusable by an end user, despite being fully implemented at the data layer.
- **Workaround**: None via the app UI; a favorite can only be added via a direct API call.
- **Planned milestone**: Not yet scheduled — flagged in RAH-DOC-046 §7 as the top concrete gate before a broader release-readiness call.
- **Status**: Open

### KI-004 — No rate limiting on any backend API endpoint
- **Severity**: High
- **Description**: No throttling/rate-limit dependency (e.g. `@nestjs/throttler`) exists in `apps/backend/package.json`, and no rate-limiting middleware or guard exists in the source tree (confirmed by source search this session).
- **Impact**: All endpoints, including public unauthenticated ones and authenticated write endpoints (reviews, favorites, verification-document uploads), are unprotected against abuse or brute-force patterns.
- **Workaround**: None currently implemented.
- **Planned milestone**: Should precede any public-facing deployment; not yet assigned to a specific roadmap phase in existing documentation.
- **Status**: Open

### KI-005 — No CI pipeline has ever executed against this codebase
- **Severity**: High
- **Description**: `.github/workflows/mobile-ci.yml` is the only CI workflow in the repository (dart format check, `flutter analyze`, `flutter test --coverage`, Android debug build) and its own file comment states it has never run against a pushed remote. Confirmed this session: local `main` is 21 commits ahead of `origin/main` (`git status -sb` / `git fetch`), so no push has occurred to trigger it. No backend CI workflow exists at all (confirmed via file search of `.github/workflows/`).
- **Impact**: No automated regression gate has ever run on this codebase; all quality signals (test pass/fail, lint, build) to date are from local runs only, verified manually each session.
- **Workaround**: Manual local verification before each commit (the practice followed throughout this project's sessions).
- **Planned milestone**: deployment-architecture.md §CI/CD Pipeline: "to be implemented Phase 3."
- **Status**: Open

### KI-006 — No monitoring, alerting, or APM tooling integrated
- **Severity**: High
- **Description**: No APM/error-tracking dependency (Sentry, Datadog, New Relic, etc.) exists in `apps/backend/package.json` or `apps/mobile/pubspec.yaml` (confirmed by dependency search this session). `docs/deployment/deployment-architecture.md` §Monitoring & Alerting describes an intended design, not a built implementation.
- **Impact**: No visibility into errors, latency, or system health beyond manual log inspection; no alerting exists for any failure condition.
- **Workaround**: Manual `logcat`/console log review (as performed in RAH-DOC-046).
- **Planned milestone**: Master Roadmap Phase 13 (per deployment-architecture.md's own phase references for observability infrastructure).
- **Status**: Deferred (by documented roadmap phasing)

## Medium

### KI-007 — Reviews CRUD not independently re-verified live this pass
- **Severity**: Medium
- **Description**: Create/update/delete/rating-aggregation for Reviews was not driven on the physical device against the real backend during Release Validation (RAH-DOC-046 §5, row 5). It has strong existing coverage: unit tests, e2e tests, widget tests, and a prior Backend Integration Audit contract verification (commit `dce1d93`).
- **Impact**: Confidence in the real-device, real-backend Reviews flow currently rests on automated test coverage only, not an on-device observation.
- **Workaround**: None needed if automated coverage is trusted; otherwise, re-run manually.
- **Planned milestone**: Flagged in RAH-DOC-046 §7 as the second concrete gate before a broader release-readiness call.
- **Status**: Open

### KI-008 — No profile-editing UI exists
- **Severity**: Medium
- **Description**: `PATCH /users/me` exists and works on the backend, but RAH-DOC-046 §5 confirms no edit-profile screen exists in the app's current UI.
- **Impact**: Users cannot update their profile information (e.g. preferred language) through the app.
- **Workaround**: None via the app.
- **Planned milestone**: Not yet scheduled in any roadmap document reviewed.
- **Status**: Open

### KI-009 — 4 of 10 backend bounded-context modules remain scaffold-only
- **Severity**: Medium
- **Description**: `access-payment`, `emergency`, `sponsorship`, and `analytics` each have 0 source files under `apps/backend/src/modules/` (confirmed by file count this session), consistent with RAH-DOC-044's explicit statement that these were deferred by instruction during Phase 4.
- **Impact**: No payment, emergency-response, sponsorship, or analytics functionality exists anywhere in the system.
- **Workaround**: None — explicitly out of scope until their designated phase.
- **Planned milestone**: Per Master Roadmap phasing referenced in RAH-DOC-044 (post-Phase-4 phases); Risk Register R-02 (payment provider) is explicitly still open by design.
- **Status**: Deferred (intentional, documented)

### KI-010 — No load or performance testing performed
- **Severity**: Medium
- **Description**: RAH-DOC-046 §8 explicitly marks API latency and memory usage as "Not verified" — no instrumentation or profiling tool was used during Release Validation; all latency observations were qualitative ("felt sub-second").
- **Impact**: NFR-PERF-01 (≤1.5s target) has not been empirically validated under any measured condition, and no concurrency/load behavior has been observed.
- **Workaround**: None.
- **Planned milestone**: Not yet scheduled in reviewed documentation.
- **Status**: Open

### KI-011 — Migration validated only against a local Supabase instance
- **Severity**: Medium
- **Description**: `prisma/migrations/20260805181420_init/` (commit `5cbe8c3`) has only ever been applied to a local `supabase start` instance. It has never been applied to a hosted/production Supabase project.
- **Impact**: A hosted deployment could still surface additional platform-specific behavior not observed locally, though the extension-declaration fix found this session (§KI-relevant, RAH-DOC-046 §6.2) is exactly the class of issue a hosted project would also have hit, and it is now fixed at the schema level.
- **Workaround**: None until a hosted project exists.
- **Planned milestone**: Tied to KI-001 (no production deployment exists yet).
- **Status**: Open

### KI-012 — Notifications feature has no mobile implementation
- **Severity**: Medium
- **Description**: The Notifications backend bounded context exists and is complete (commit `d540f9a`, 27 files), but no corresponding Flutter repository, DTO, provider, or inbox screen exists. This was explicitly and intentionally excluded from the Phase 5 Backend Integration Audit pass per direct user instruction (documented in RAH-DOC-045).
- **Impact**: End users have no way to view or manage notifications in the app despite the backend fully supporting it.
- **Workaround**: None.
- **Planned milestone**: Not yet scheduled; excluded by explicit scope decision, not roadmap phasing.
- **Status**: Deferred (intentional, by explicit instruction)

## Low

### KI-013 — Token refresh behavior not empirically observed
- **Severity**: Low
- **Description**: RAH-DOC-046 §5, row "Token refresh," confirms this was verified only by reading `gotrue-2.26.0`'s source (`autoRefreshToken` defaults to `true`), not by observing a real token expiry and refresh in a live session (session tokens last 1 hour; not practical to wait out during validation).
- **Impact**: Low — this is standard, library-guaranteed SDK behavior, but it has not been independently confirmed to work correctly in this app's integration.
- **Workaround**: None needed unless a future defect surfaces.
- **Planned milestone**: Could be re-verified in any future validation pass with a longer session window.
- **Status**: Open

### KI-014 — Operations module's site-scope filtering not implemented
- **Severity**: Low
- **Description**: No `Site` entity exists in the ERD; Operations endpoints cannot filter by site scope, as already documented in RAH-DOC-044 and `apps/backend/prisma/README.md`.
- **Impact**: Only affects the not-yet-built Operator Dashboard consumer; no current client (including the Flutter app) is affected.
- **Workaround**: None needed at this time — no consumer depends on this yet.
- **Planned milestone**: To be addressed alongside the Operator Dashboard's own roadmap phase (not yet started).
- **Status**: Deferred (intentional, documented)

### KI-015 — Telemetry ingestion (IoT pipeline) entirely unbuilt
- **Severity**: Low
- **Description**: `telemetry_reading` table exists in the schema but has no ingestion path; `battery_level`, `water_level`, and occupancy-history fields are always null/empty, as documented in `apps/backend/prisma/README.md`.
- **Impact**: No current V1 end-user flow depends on live telemetry; only future IoT-integration features would be affected.
- **Workaround**: None needed at this time.
- **Planned milestone**: Master Roadmap Phase 9 (IoT/telemetry).
- **Status**: Deferred (intentional, documented)

---

## Summary Table

| ID | Severity | Title | Status |
|---|---|---|---|
| KI-001 | Critical | No production backend/database deployment exists | Open |
| KI-002 | Critical | Android release build uses debug signing | Open |
| KI-003 | High | Favorites has no "add" UI | Open |
| KI-004 | High | No rate limiting on any backend endpoint | Open |
| KI-005 | High | No CI pipeline has ever executed | Open |
| KI-006 | High | No monitoring/alerting/APM integrated | Deferred |
| KI-007 | Medium | Reviews CRUD not re-verified live | Open |
| KI-008 | Medium | No profile-editing UI | Open |
| KI-009 | Medium | 4 of 10 backend modules scaffold-only | Deferred |
| KI-010 | Medium | No load/performance testing performed | Open |
| KI-011 | Medium | Migration validated only against local Supabase | Open |
| KI-012 | Medium | Notifications has no mobile implementation | Deferred |
| KI-013 | Low | Token refresh not empirically observed | Open |
| KI-014 | Low | Operations site-scope filtering not implemented | Deferred |
| KI-015 | Low | Telemetry ingestion entirely unbuilt | Deferred |
