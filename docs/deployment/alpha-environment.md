# Alpha Environment Setup

**Scope note**: this is an interim, minimal environment to get a real
HTTPS-reachable backend in front of mobile testers — it is **not** the
Phase 3/13 production topology described in
[`deployment-architecture.md`](./deployment-architecture.md) (no load
balancer, no multi-instance API, no IoT ingestion/MQTT), and it does not
resolve [ADR-0016](../adr/0016-hosting-provider-selection.md) (hosting
provider is still Proposed, not Accepted — Alpha may borrow a candidate
from that shortlist for a throwaway environment without that being a
production decision). Local development (`supabase start`, `apps/backend/.env`,
`npm run start:dev`) is unaffected by anything in this document.

## 1. What Alpha needs, and why

| Piece | Status | Needed for |
|---|---|---|
| Dedicated Supabase project ("alpha" tier) | Not created | `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, hosted Postgres (`DATABASE_URL`), Auth |
| Backend container image | `apps/backend/Dockerfile` now exists (this change) | Deployable artifact for any hosting target |
| Backend hosting (e.g. Fly.io/Render — ADR-0016 candidates) | Not provisioned | Reachable HTTPS `API_BASE_URL` |
| Hosted-DB schema | Not migrated | `prisma migrate deploy` against the new project (see §3) |
| Mobile release secrets | Not set | The 3 `--dart-define` values `mobile-release.yml` needs (tracked separately — not added by this change; no GitHub Actions deployment workflow is added here) |

## 2. Environment variables

### Backend runtime (set on whatever hosts the container — not committed anywhere)

Same shape as `apps/backend/.env.example`, pointed at the hosted Alpha
Supabase project instead of local values:

| Variable | Local dev value (`.env.example`) | Alpha value comes from |
|---|---|---|
| `NODE_ENV` | `development` | `production` |
| `PORT` | `3000` | Usually assigned by the hosting platform; `main.ts` reads `process.env.PORT` (default `3000` — `configuration.ts`) |
| `DATABASE_URL` | local Postgres | Alpha Supabase project → Project Settings → Database → Connection string |
| `SUPABASE_URL` | `https://your-project.supabase.co` | Alpha Supabase project → Project Settings → API |
| `SUPABASE_JWT_JWKS_URL` | `https://your-project.supabase.co/auth/v1/.well-known/jwks.json` | Same Supabase project (derived from its URL) |
| `SUPABASE_JWT_SECRET` | empty | Leave empty unless the Alpha project is a legacy (HS256) Supabase project — see `.env.example`'s own comment |
| `CORS_ALLOWED_ORIGINS` | `raahti.dz`/`ops.`/`sponsors.` | Mobile is exempt (native HTTP, not a browser origin — `.env.example`'s own comment); only relevant if a web/dashboard client also targets Alpha |
| `OSRM_BASE_URL` | public OSRM demo | Can stay as the public demo server for Alpha (no uptime SLA, acceptable for internal testing) |

### Mobile release (`--dart-define`, consumed by `apps/mobile/lib/core/constants/env.dart`)

| Variable | Value |
|---|---|
| `SUPABASE_URL` | Same Alpha Supabase project URL as above |
| `SUPABASE_PUBLISHABLE_KEY` | Alpha Supabase project → Project Settings → API → anon/publishable key |
| `API_BASE_URL` | The Alpha backend's HTTPS URL (whatever the hosting platform assigns, e.g. `https://rahati-alpha.fly.dev`) |

This document only records *what* these values are and *where they come
from* — it does not create the GitHub Secrets or CI wiring to inject them
(that's explicitly out of scope for this change; see `mobile-release.yml`
planning notes tracked separately).

## 3. Migration path (local Supabase → hosted Alpha)

1. **Provision** the Supabase "alpha" project (dashboard). Note its URL,
   anon/publishable key, and JWKS URL.
2. **Apply the schema**: `npx prisma migrate deploy` against the new
   project's `DATABASE_URL` — **not** `prisma migrate dev` (that command is
   local-dev-only; it can create a shadow database and prompt for
   destructive resets, neither appropriate against a shared hosted
   environment). See `apps/backend/prisma/README.md`'s new "Alpha
   environment migration" section for the exact command and what it
   applies.
3. **Build the image**: `docker build -t rahati-backend -f apps/backend/Dockerfile apps/backend`.
4. **Deploy** the image to the chosen host, with the runtime env vars from
   §2 above set in that platform's own secret/env store (not in the repo).
5. **Verify** `GET /health` responds `200` over the deployed HTTPS URL from
   outside the deploy network (not `localhost`) — this endpoint already
   checks live DB connectivity (`HealthController`), so a `200` confirms
   both the container and its DB connection are working end-to-end.
6. **Point mobile at it**: set the 3 `--dart-define` values from §2 wherever
   the mobile release build sources them from, replacing the
   `localhost`/`adb reverse` values used for local Phase 5 validation
   (`docs/phase-5-release-validation-report.md`).
7. **Re-run on-device validation** against the hosted Alpha backend over a
   real network (not loopback) before considering "Aucun serveur configuré"
   resolved for real testers.
8. **Local Supabase stack is unaffected** — it remains the day-to-day dev
   target; Alpha/staging/production stay isolated, separate Supabase
   projects (`deployment-architecture.md` §1's existing environment-isolation
   rule applies to Alpha too).

## 4. Explicitly not done by this document or its accompanying change

- No Supabase project has been created.
- No hosting provider/account has been provisioned.
- No GitHub Actions workflow builds, pushes, or deploys this image.
- No secrets have been added anywhere.
- `deployment-architecture.md` (the production topology) is unchanged.
