# RAHATI OSRM routing infrastructure

Self-hosted, Docker-based OSRM (foot profile) routing engine for RAHATI's
`/v1/routes/walking` backend endpoint. This directory replaces reliance on
the public OSRM demo server (`https://router.project-osrm.org`), which was
found during real-device QA (2026-08-27) to return car-speed durations for
`/foot/`-profile requests — a 1.9km route reported as a 3-minute walk.

**RAHATI's backend code does not know this directory exists.** It only ever
reads `OSRM_BASE_URL` (`apps/backend/.env` / `.env.example`). Pointing the
backend at this service — local or remote — is a configuration change, not
a code change. Nothing here modifies `apps/backend` or `apps/mobile`.

**Deploying this to a real server?** See [PRODUCTION.md](./PRODUCTION.md)
for the operator checklist (server sizing, firewall, boot persistence,
monitoring, scheduled data refresh, security checklist) — this README
covers the infrastructure itself, PRODUCTION.md covers running it for real.

## Architecture

```
RAHATI mobile app
  -> GET {API_BASE_URL}/v1/routes/walking            (unchanged)
       -> apps/backend RoutingController/RouteQueryService (unchanged)
            -> OsrmRouteProvider, reads OSRM_BASE_URL     (unchanged)
                 -> GET {OSRM_BASE_URL}/route/v1/foot/... -> THIS SERVICE
```

`RouteQueryService` also still rejects any route (from this or any other
provider) whose implied walking speed exceeds 10 km/h
(`apps/backend/src/modules/routing/domain/walking-route-plausibility.ts`) —
**self-hosting OSRM does not remove that safety check, and it must not be
removed** just because the data source is now trusted. It is the last line
of defense against a bad dataset, a bad reload, or a future regression.

## OSRM version

Pinned to **`ghcr.io/project-osrm/osrm-backend:v5.27.1`** (official image,
published by the OSRM project itself under GitHub Container Registry) —
never `:latest`. Chosen because:
- It is a tagged, immutable release (reproducible: the same tag always
  pulls the same image), not a moving target.
- It is the MLD-pipeline-capable generation (`osrm-partition`/
  `osrm-customize`), the pipeline this repo's scripts use — MLD has lower
  preprocessing memory needs than the older CH (contraction hierarchies)
  pipeline for a country-sized extract, which matters for reproducing this
  setup on modest hardware (see "Resource requirements").
- It is a stable, widely-deployed release at the time this infrastructure
  was built, with no known regressions relevant to the foot profile.

To upgrade later: change the tag in **both** `docker-compose.yml` and
`scripts/preprocess.sh` (kept as plain string literals, deliberately not
templated, so a version bump is a visible, reviewable diff in exactly two
places) — then re-run the full preprocessing pipeline (a `.osrm` dataset is
not guaranteed compatible across OSRM major/minor versions) and
`scripts/test-route.sh` before switching production traffic to it.

## Data source

- **Provider**: [Geofabrik](https://download.geofabrik.de/) — the standard,
  reputable country/region OSM-extract provider used throughout the
  OSM/OSRM ecosystem (not an arbitrary/unofficial mirror).
- **URL**: `https://download.geofabrik.de/africa/algeria-latest.osm.pbf`
  (configurable via `OSRM_PBF_URL` in `.env` — see `.env.example`).
- **Update cadence**: Geofabrik regenerates `*-latest.osm.pbf` from OSM daily;
  `scripts/download-data.sh` saves each download under its own UTC date
  (`data/raw/algeria-YYYYMMDD.osm.pbf`) so you always know exactly which
  day's data any given release was built from.
- **Format/licence**: OpenStreetMap data, ODbL — same licence terms RAHATI's
  mosque importer (`apps/backend/src/scripts/osm-mosque-import/`) already
  operates under; no new licensing consideration introduced.

## Preprocessing pipeline (MLD)

```
osrm-extract  -p profiles/foot.lua  algeria-latest.osm.pbf   -> algeria-latest.osrm
osrm-partition                      algeria-latest.osrm
osrm-customize                      algeria-latest.osrm
```

All three run inside the exact same pinned `osrm-backend` image the routing
container serves from, using the **project's own unmodified `foot.lua`**
profile at `/usr/local/share/osrm/profiles/foot.lua` inside that image —
never a forked/edited copy. `scripts/preprocess.sh` automates all three
steps into a dated, isolated release directory:

```bash
cd infra/osrm
cp .env.example .env               # first time only; edit if needed
./scripts/download-data.sh
./scripts/preprocess.sh ./data/raw/algeria-YYYYMMDD.osm.pbf
```

This never touches the currently-serving dataset (`data/current`) — see
"Data update strategy" below for activating the result.

## Environment variables

All consumed from `infra/osrm/.env` (copy from `.env.example`, never
commit the real file — see root `.gitignore`):

| Variable | Default | Purpose |
|---|---|---|
| `OSRM_REGION` | `algeria` | Dataset basename; must match what `preprocess.sh` produced |
| `OSRM_DATA_DIR` | `./data` | Where raw downloads + processed releases + the `current` symlink live |
| `OSRM_HOST_PORT` | `5000` | Host port `osrm-routed` is published on |
| `OSRM_BIND_ADDRESS` | `127.0.0.1` | Interface the host port is bound to — see "Security" |
| `OSRM_PBF_URL` | Algeria Geofabrik URL | Source for `download-data.sh` |

This is a **separate** `.env` from `apps/backend/.env` — RAHATI's own
`OSRM_BASE_URL` variable is documented below in "Backend integration", not
here.

## Running it

```bash
cd infra/osrm
docker compose up -d
./scripts/healthcheck.sh
```

## Health check

A container merely running proves nothing about routing actually working —
so both the Compose `healthcheck:` (runs *inside* the container, using only
bash's `/dev/tcp` since the official image has no curl/wget) and the
standalone `scripts/healthcheck.sh` (runs from the host, using curl) send a
real `/route/v1/foot/...` request for two points a few hundred meters apart
in central Algiers and require `"code":"Ok"` in the response — a listening
port with no usable road graph loaded is reported unhealthy, not healthy.

`docker compose ps` shows the health state; `docker inspect --format
'{{.State.Health.Status}}' rahati-osrm` for scripting.

## Test route (documented functional test)

`scripts/test-route.sh` requests the **same route shape that exposed the
original RAHATI defect** — Constantine, ~1.9km (Mosquée Hassan Bey area) —
against a running service, or a disposable one-off container for a
not-yet-activated release (`--release <path>`):

```bash
./scripts/test-route.sh                              # against the running service
./scripts/test-route.sh --release ./data/releases/algeria-20260827T140615Z
```

It asserts HTTP 200, valid JSON, a real route (`code:"Ok"`), `distance > 0`,
`duration > 0`, and an implied speed between 0.5–10 km/h — the upper bound
intentionally mirrors
`apps/backend/src/modules/routing/domain/walking-route-plausibility.ts`'s
own ceiling, so this test fails loudly if a self-hosted deployment ever
reproduced the original defect (it does not hardcode an exact expected
ETA, since real road data can legitimately change route timing slightly
between Geofabrik updates).

## Data update strategy

1. `./scripts/download-data.sh` — new dated `.osm.pbf` into `data/raw/`.
2. Integrity check is automatic (OSMHeader magic + minimum size — see the
   script; a real corruption-resistant check would use `osmium fileinfo`,
   not bundled in the routing image, so this is a lightweight sanity check,
   not a cryptographic one).
3. `./scripts/preprocess.sh <pbf>` — extract → partition → customize, into
   a **new** `data/releases/<region>-<timestamp>/` directory.
4. `./scripts/test-route.sh --release <new-release-dir>` — validates it in
   a disposable container, **before** it ever serves real traffic.
5. `./scripts/switch-dataset.sh <new-release-dir> --restart` — atomically
   repoints the `data/current` symlink (rename-based swap, never a
   window where the symlink is missing/half-written) and restarts
   `osrm-routed` to load it.
6. `./scripts/healthcheck.sh` — confirm the live service came back healthy
   on the new dataset.
7. Once confident, optionally delete old releases under `data/releases/`
   to reclaim disk — **not automatic**, see "Backup / rollback".

`scripts/refresh.sh` automates steps 1–6 as a single cron/systemd-timer-safe
command for unattended production use (see
[PRODUCTION.md §10](./PRODUCTION.md#10-algeria-osm-data-refresh-production-automation))
— it only activates a new dataset if validation passes, and never touches
the currently-serving one otherwise.

## Backup / rollback

Every `preprocess.sh` run creates a new, independent, timestamped directory
under `data/releases/` — the previous one is **never deleted** by any
script here. Rolling back is switching the symlink back:

```bash
ls data/releases/                                    # find the previous one
./scripts/switch-dataset.sh data/releases/algeria-<older-timestamp> --restart
```

Disk cleanup of old releases is a deliberate manual/operator decision
(`rm -rf data/releases/<old-one>`), never automated, so a rollback target is
never silently gone.

## Security

- `osrm-routed` is bound to `127.0.0.1` by default (`OSRM_BIND_ADDRESS`) —
  reachable only from the same host, **not** the public internet. If the
  RAHATI backend runs on a different host than OSRM, widen this to a
  private-network address (e.g. a VPC-internal IP or Docker overlay
  network member address) — never `0.0.0.0` on a host with a public IP.
- No authentication is added to OSRM itself — it is an internal dependency
  of the RAHATI backend, which remains the sole public-facing gateway
  (`GET /v1/routes/walking`, already rate-limited — see
  `apps/backend/src/modules/routing/interface/controllers/routing.controller.ts`).
  Adding auth in front of OSRM would be redundant defense-in-depth this
  deployment's threat model doesn't currently call for; revisit if OSRM
  is ever exposed beyond a trusted private network.
- Only port 5000 (OSRM's own default) is ever exposed, and only on the
  configured host port/interface — no other ports from the image are
  published.
- No secrets are involved anywhere in this pipeline (Geofabrik downloads
  and the OSRM image are both public/anonymous).

## Backend integration

Set in `apps/backend/.env` (**not** anything in this directory):

```bash
# Same host, Docker Compose default network name resolution:
OSRM_BASE_URL=http://osrm:5000
# Backend running as a plain process on the same host as this compose project:
OSRM_BASE_URL=http://127.0.0.1:5000
# Backend and OSRM on separate hosts (private network):
OSRM_BASE_URL=http://<osrm-host-private-ip>:5000
```

`http://osrm:5000` only resolves if the RAHATI backend container joins this
compose project's network (e.g. via `docker-compose.yml`'s `networks:` —
not configured by default, since `apps/backend` is not deployed via Compose
in this repo today; add it there, not here, if/when it is). No code change
either way — this is purely `.env`.

## Resource requirements

Measured on this development machine (12 CPU, ~8GB RAM allocated to Docker
Desktop, Algeria extract ≈ 285MB from Geofabrik, 2026-08-27):

| Stage | Observed |
|---|---|
| Download (.osm.pbf) | 285 MB (300MB per Geofabrik's `Content-Length`) |
| `osrm-extract` (foot profile) | ~90s, peak RAM 2.75 GB |
| `osrm-partition` | ~36s, peak RAM 1.32 GB |
| `osrm-customize` | ~4s, peak RAM 0.91 GB |
| **Total preprocessing** | **~2.5 minutes**, peak RAM **2.75 GB** (during extract — the highest of the three stages) |
| Processed dataset size (`data/current/`) | 1.2 GB |
| Runtime RAM (`osrm-routed` serving) | well under 1GB observed — much lighter than preprocessing |

**Do not assume these numbers generalize to a much larger extract** (e.g. a
multi-country or continental `.osm.pbf`) — Algeria turned out considerably
cheaper to process than a naive "large country -> large resource need"
assumption would suggest, precisely because its road *network* density is
moderate despite its large land area (much of the country is sparse
desert). Preprocessing time and RAM scale with actual OSM
node/way/relation count, not raw file size or geographic area — a denser
or larger region should be expected to need more of both.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `osrm-routed` exits immediately, "no such file" | `data/current` symlink missing/wrong `OSRM_REGION` — check `docker compose logs osrm` |
| Healthcheck fails, container "running" | Dataset loaded but profile mismatch, or algorithm mismatch (`--algorithm mld` must match how the dataset was processed) |
| `osrm-extract` argument/profile path errors under Git Bash on Windows | MSYS path mangling — `scripts/preprocess.sh` already sets `MSYS_NO_PATHCONV=1`; if you invoke `docker run` manually from Git Bash, do the same |
| Slow/failed Geofabrik download | Geofabrik has no formal uptime SLA; retry, or mirror the `.osm.pbf` internally if this becomes recurring |
| `osrm-routed` exits instantly with **zero** log output, even at `--verbosity DEBUG` | Found during this setup: passing a very restrictive `--max-table-size` (e.g. `1`) crashes `osrm-routed` v5.27.1 before logging even initializes. RAHATI never calls `/table/`, so this flag is not set at all — do not re-add it without testing a real request against it first |
| `ln: failed to create symbolic link` running `switch-dataset.sh`/`preprocess.sh` on Windows | Git Bash's `ln -s` needs Developer Mode or an elevated shell on Windows to create real symlinks; on a real (Linux) production host this is a non-issue. For local Windows testing only, activate a release with a directory junction instead: `New-Item -ItemType Junction -Path data\current -Target data\releases\<release>` (PowerShell, no elevation required) |
| `switch-dataset.sh` warns about missing sibling files | `preprocess.sh` didn't complete all three stages — re-run it, don't activate a partial release |
