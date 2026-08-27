# RAHATI OSRM — Production Deployment Plan

Companion to [README.md](./README.md) (architecture, version rationale, data
pipeline, scripts) — this document is specifically the **operator's
checklist for putting this on a real server**. Nothing in this file has
been executed against a real production host: RAHATI's hosting provider is
itself still an open decision
([ADR-0016](../../docs/adr/0016-hosting-provider-selection.md), status
"Proposed"), so this plan is deliberately **provider-agnostic** — it works
identically on a plain Ubuntu/Debian VPS from any of the shortlisted
candidates (AWS, OVHcloud, Fly.io, Render) or any other Docker-capable
Linux host.

**Nothing here changes RAHATI application code, Flutter, Places/Mosques/
Stations/Cabins/Auth, or the PostGIS schema.** This is Docker + OS-level
configuration + documentation only.

## 1. Recommended architecture

**If the RAHATI backend and OSRM run on the same host (recommended,
default choice):**

```
                         Internet
                            |
                       (HTTPS, firewall)
                            |
                    RAHATI backend process
                    (bare process / systemd / its own Docker
                     container — apps/backend/Dockerfile)
                            |
                    http://127.0.0.1:5000    <- loopback only, never
                            |                   leaves the host
                    OSRM container (this compose project)
                    bound to 127.0.0.1, not 0.0.0.0
```

This is the configuration already built and verified locally this session:
`OSRM_BASE_URL=http://127.0.0.1:5000`, OSRM's host port bound to
`127.0.0.1` only. It is the *safest possible* "private network" — loopback
traffic never touches a NIC, a switch, or anything sniffable, and there is
no firewall rule that could accidentally be misconfigured to expose it,
because it was never bound to a routable interface at all.

**If the RAHATI backend and OSRM must run on separate hosts** (e.g.
backend on a managed PaaS with no persistent-disk story for the ~1.2GB
dataset, or a dedicated routing box for capacity reasons):

```
RAHATI backend host                    OSRM host
--------------------                   ---------
backend process          --private--   OSRM container
                          network       bound to the private
                                        interface's IP, e.g.
                                        10.x.x.x:5000
```

Safest options, in order of preference:
1. **Cloud provider VPC/private networking** (AWS VPC, OVHcloud vRack,
   etc.) — the two hosts communicate over an address range that is not
   internet-routable at all. Set `OSRM_BIND_ADDRESS` in `infra/osrm/.env`
   to the OSRM host's private-network IP (never `0.0.0.0`), and
   `OSRM_BASE_URL=http://<that-private-ip>:5000` in `apps/backend/.env`.
2. **WireGuard (or equivalent) point-to-point tunnel** between the two
   hosts if the provider has no native private networking (e.g. two
   independent VPS providers) — OSRM binds to the WireGuard interface's
   address, not the public one.
3. **SSH tunnel / cloud provider firewall rule scoped to the backend
   host's exact IP** as a last resort — workable, more operationally
   fragile (an IP change breaks it silently) than the above two.

Never use a bare public IP + "just don't tell anyone the port" — that is
not a security boundary.

## 2. Server requirements

Sized from this session's real measurement on the Algeria dataset (see
README.md "Resource requirements" for the exact numbers) plus operating
margin:

| Resource | Preprocessing (occasional, see §7) | Steady-state serving |
|---|---|---|
| CPU | 2+ cores (12 were available in testing but not the bottleneck; extraction is I/O+CPU bound, more cores shorten it, are not required) | 1–2 cores comfortably handles a country-sized MLD dataset at modest RAHATI traffic volumes |
| RAM | **4 GB minimum**, 8 GB comfortable (measured peak was 2.75 GB during `osrm-extract`; leave headroom for the OS + Docker + a concurrent `osrm-routed` still serving traffic during a refresh) | well under 1 GB observed for `osrm-routed` itself |
| Disk | **10 GB minimum** free at all times: ~300MB raw `.pbf` + ~1.2GB per processed release, and §9 keeps at least the current + previous release on disk simultaneously by design | 1.2 GB per retained release (see §9 for retention policy) |
| Docker | Docker Engine 24+ with Compose v2 (`docker compose`, not the standalone `docker-compose` v1 binary — this project's compose file uses Compose Specification syntax) | — |
| OS | Any Linux Docker officially supports (Ubuntu 22.04/24.04 LTS or Debian 11/12 are the most common VPS defaults and were this project's implicit target) | — |

These figures are **Algeria-specific** (see README.md's explicit warning) —
re-measure with `docker stats` during a real preprocessing run before
assuming they hold for a different/larger region.

## 3. Firewall

OSRM's port (5000 by default) must **never** appear in a public-facing
firewall/security-group allow-list. Concretely, on a host using `ufw`:

```bash
sudo ufw default deny incoming
sudo ufw allow OpenSSH                 # or your actual SSH port
sudo ufw allow 443/tcp                 # RAHATI backend's public HTTPS, if it terminates TLS on this host
# Do NOT add: sudo ufw allow 5000
sudo ufw enable
```

On a cloud provider's security-group/firewall UI instead of host `ufw`,
the equivalent rule is: **no inbound rule for port 5000 at all** (default
deny covers it). If backend and OSRM are on separate hosts using a
provider VPC (§1), the OSRM host's security group should allow port 5000
**only** from the backend host's private IP/security-group — never
`0.0.0.0/0`.

Verify after setup:
```bash
# From outside the host (e.g. your laptop) — this MUST time out/refuse:
curl -m 5 http://<server-public-ip>:5000/route/v1/foot/3.05,36.75;3.06,36.76
# From inside the host — this MUST succeed:
curl http://127.0.0.1:5000/route/v1/foot/3.05,36.75;3.06,36.76
```

## 4. OS/Docker boot persistence

`restart: unless-stopped` (already in `docker-compose.yml`) brings the
container back after a crash or a Docker daemon restart, but only if the
Docker daemon itself starts on host boot:

```bash
sudo systemctl enable docker
sudo systemctl is-enabled docker   # should print "enabled"
```

That is sufficient for most single-host deployments — no extra systemd
unit is required. If your ops process prefers an explicit, inspectable
systemd unit for this compose project specifically (e.g. to express "OSRM
depends on the data disk being mounted" as a real systemd dependency
rather than an implicit assumption), a template:

```ini
# /etc/systemd/system/rahati-osrm.service
[Unit]
Description=RAHATI OSRM routing service (Docker Compose)
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/rahati/infra/osrm      # adjust to actual deployment path
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now rahati-osrm.service
```

This is a template, not a committed file — `WorkingDirectory` is
deployment-specific, so it is documented here for the operator to copy and
adapt rather than shipped as something that could be run unedited.

## 5. Persistent routing data

`OSRM_DATA_DIR` (in `infra/osrm/.env`) should point at a path on
persistent disk that survives container recreation and, ideally, host
replacement — e.g. a mounted block-storage volume, not the VPS's
ephemeral root disk if your provider distinguishes the two. Default
(`./data`, inside the repo checkout) is fine for a single, simple VPS with
one persistent root disk; move it (e.g. `/var/lib/rahati-osrm`, or a
mounted volume) only if your provider's disk model calls for it.

The dataset itself never needs backing up beyond what §9 (rollback)
already keeps on disk — it is fully reproducible from Geofabrik on demand
(`scripts/download-data.sh` + `scripts/preprocess.sh`), so it is
deliberately excluded from any RAHATI database backup strategy.

## 6. RAHATI backend connectivity / `OSRM_BASE_URL`

Set in `apps/backend/.env` on the backend host (never in this directory):

| Deployment | `OSRM_BASE_URL` |
|---|---|
| Same host, OSRM in this Docker Compose project | `http://127.0.0.1:5000` |
| Same host, backend also containerized and joined to this compose network | `http://osrm:5000` |
| Separate hosts, private network (§1) | `http://<osrm-private-ip>:5000` |

No code change in any case — confirmed working end-to-end in this session
with the first row (`http://127.0.0.1:5000`), including a real physical
Android device successfully navigating through it.

## 7. HTTPS / reverse proxy

**Not required in front of OSRM itself** in either recommended topology
(§1): loopback traffic needs no TLS (nothing between the two processes
that TLS would protect against), and a proper cloud-provider private
network (VPC) is already an isolated, non-internet-routable segment.

Only consider adding a reverse proxy (nginx/Caddy) with TLS in front of
OSRM if:
- The private network between backend and OSRM hosts is **not** a true
  VPC (e.g. a shared/multi-tenant network you don't fully trust) — in that
  case, terminate TLS at a small nginx/Caddy sidecar in front of
  `osrm-routed` and have the backend's `OSRM_BASE_URL` point at `https://`
  instead. This is not built here (no such untrusted-network deployment is
  planned), but the option is documented since the task asks for it "if
  applicable."
- OSRM ever needs to be reachable by anything other than the RAHATI
  backend itself — it currently does not, and should not.

RAHATI's own public HTTPS termination (`GET /v1/routes/walking`) is
unrelated and already exists — no change here.

## 8. Health monitoring

Two layers already exist and require no new tooling:

1. **Docker's own health status** (`docker-compose.yml`'s `healthcheck:`)
   — `docker inspect --format '{{.State.Health.Status}}' rahati-osrm`, or
   `docker compose ps`. Poll this from whatever the ops team's existing
   monitoring/alerting stack is (RAHATI's own alerting routing is itself
   still a "Phase 13" open item per
   [deployment-architecture.md §6](../../docs/deployment/deployment-architecture.md#6-monitoring--alerting)
   — this plan does not invent a specific tool ahead of that decision).
   Minimal, dependency-free fallback if nothing else exists yet: a cron
   entry running `scripts/healthcheck.sh` and alerting (email/webhook — pick
   whatever's already available) on non-zero exit:
   ```cron
   */5 * * * * cd /opt/rahati/infra/osrm && ./scripts/healthcheck.sh || echo "OSRM unhealthy" | mail -s "RAHATI OSRM alert" ops@example.test
   ```
2. **RAHATI's own existing observability** — a failing/unreachable OSRM
   surfaces as `RouteProviderUnavailableException` (502) through the
   backend's normal structured logging and exception filter (see
   `apps/backend/src/platform/http/http-exception.filter.ts`), so it is
   already visible in whatever log aggregation RAHATI's backend already
   reports to, without any OSRM-specific integration — this was true
   before this task and remains true now.

## 9. Backup / rollback

Unchanged from README.md's existing policy, restated here for the
production checklist: every `scripts/preprocess.sh` run (directly, or via
`scripts/refresh.sh`, see §10) creates a new `data/releases/<timestamp>/`
directory and never deletes an old one. `data/current` is a symlink (a
directory junction if activated from Windows during testing — see
README.md Troubleshooting; a real symlink on the Linux production host).

**Rollback**, at any time, to the previous known-good dataset:
```bash
cd infra/osrm
ls data/releases/                                       # find the previous timestamp
./scripts/switch-dataset.sh data/releases/algeria-<older-timestamp> --restart
./scripts/healthcheck.sh                                # confirm it's serving again
```

**Retention policy for production**: keep at minimum the **current** and
**immediately previous** release on disk at all times (never delete the
one you'd roll back to); only remove older ones, and only after the
current release has been serving successfully for a reasonable burn-in
period (a few days is a reasonable default, no hard rule is imposed by
tooling here — this is an operator judgment call, deliberately not
automated, exactly as README.md's existing "Backup / rollback" section
already states).

## 10. Algeria OSM data refresh (production automation)

`scripts/refresh.sh` (new in this task) chains the existing
download/preprocess/validate/switch/healthcheck steps into one
cron/systemd-timer-safe operation: **it only ever activates a new dataset
if `test-route.sh` validates it first**, and leaves the current dataset
completely untouched on any failure at any step (network failure,
corrupted download, preprocessing failure, an implausible-speed result,
or a failed post-switch healthcheck).

```cron
# Weekly, Sunday 03:00 UTC — Algeria's road network doesn't change fast
# enough to warrant daily refreshes; adjust to your own change-tolerance.
0 3 * * 0 cd /opt/rahati/infra/osrm && ./scripts/refresh.sh >> /var/log/rahati-osrm-refresh.log 2>&1
```

or as a systemd timer (`rahati-osrm-refresh.timer` +
`rahati-osrm-refresh.service` running `ExecStart=.../scripts/refresh.sh`,
same template pattern as §4) if that fits the host's existing conventions
better than cron.

## 11. Security checklist (pre-launch)

- [ ] OSRM's host port is bound to `127.0.0.1` or a private-network IP —
      confirmed via the §3 "from outside the host" curl test failing.
- [ ] No public firewall/security-group rule allows inbound traffic to
      OSRM's port from `0.0.0.0/0`.
- [ ] `infra/osrm/.env` (if it deviates from `.env.example`) is **not**
      committed — already covered by root `.gitignore`; re-verify with
      `git check-ignore -v infra/osrm/.env` on the actual deployment
      checkout.
- [ ] Docker daemon starts on boot (`systemctl is-enabled docker`).
- [ ] `data/current` points at a release that has passed
      `scripts/test-route.sh`.
- [ ] `apps/backend/.env`'s `OSRM_BASE_URL` points at this service (not
      left on the public OSRM demo default) — grep for it, don't assume.
- [ ] The 10 km/h walking-speed plausibility check in
      `apps/backend/src/modules/routing/domain/walking-route-plausibility.ts`
      is present and unmodified — this is RAHATI application code and out
      of scope for this task to touch, but its continued presence is a
      precondition for calling routing "production ready," per the
      original task that created it.

## 12. Step-by-step deployment procedure

```bash
# On the target server:
git clone <rahati-repo> /opt/rahati        # or however this repo is deployed
cd /opt/rahati/infra/osrm
cp .env.example .env
# Edit .env if this host's paths/ports differ from the defaults, and set
# OSRM_BIND_ADDRESS to the private-network IP if backend/OSRM are on
# separate hosts (§1) — leave as 127.0.0.1 for the same-host default.

./scripts/download-data.sh
./scripts/preprocess.sh ./data/raw/algeria-<date>.osm.pbf
# Note the "RELEASE_DIR=..." line it prints.

./scripts/test-route.sh --release <that RELEASE_DIR>
# Only proceed if this prints "PASS: plausible walking route."

mkdir -p data && ln -sfn <that RELEASE_DIR> data/current   # first activation only;
                                                            # use switch-dataset.sh for every activation after this one
docker compose up -d
./scripts/healthcheck.sh

# On the RAHATI backend host (same host or separate, per §1/§6):
# set OSRM_BASE_URL in apps/backend/.env, then restart the backend process.

# Verify end-to-end:
curl "http://<backend-host>/v1/routes/walking?originLat=<lat>&originLng=<lng>&destLat=<lat2>&destLng=<lng2>"
# distanceMeters/durationSeconds should imply a walking-plausible speed
# (roughly 3-7 km/h for a typical route) — if it 502s, check
# RouteProviderUnavailableException in the backend logs and OSRM's own
# healthcheck first.
```

Set up §4 (boot persistence), §10 (scheduled refresh), and §8
(monitoring) as ongoing operational tasks, not one-time setup.

## 13. What this plan does NOT do (explicit scope boundary)

- **No server was provisioned or purchased.** This plan assumes an
  operator with an already-provisioned Linux host runs the commands in
  §12.
- **No production traffic has been routed through a production
  deployment.** Everything verified so far (README.md's own report) ran
  on the local development machine — real Algeria data, a real container,
  a real physical Android device — but on `127.0.0.1`, not a reachable
  production server.
- **No specific hosting provider was chosen** — deliberately, since
  [ADR-0016](../../docs/adr/0016-hosting-provider-selection.md) itself is
  still open. Nothing here blocks any of the shortlisted candidates.
- **No monitoring/alerting tool was integrated** — RAHATI-wide alerting
  routing is itself an open "Phase 13" decision; §8 gives a
  zero-dependency fallback that works regardless of what gets chosen
  later.
