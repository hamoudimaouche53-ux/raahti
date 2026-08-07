# Prisma schema notes

No **hosted** Supabase project has been deployed yet (ADR-0016 hosting is still
Proposed). The first real migration (`migrations/20260805181420_init/`) was authored
and applied during Release Validation (`docs/phase-5-release-validation-report.md`)
against a **local** Supabase stack (`supabase start`, Docker) — the same schema, same
manual SQL, same target every hosted Supabase project would need. It includes every
item that used to be listed below as "once a live database exists": the GIST spatial
indexes and the four hand-written `CHECK` constraints. Applying this same migration
directory (`prisma migrate deploy`) against a real hosted project once ADR-0016 is
resolved needs no further authoring — this doc is now a record of what's already in
`migrations/`, not a to-do list.

A second migration (`migrations/20260806121959_access_payment/`) adds the Access &
Payment bounded context (`AccessSession`, `Transaction`, `IdempotencyKey`) — see
"## Access & Payment module" below for how it was generated and its current
generated-but-not-yet-applied state.

One real gap found in the process, fixed directly in `schema.prisma`: Supabase's own
Postgres image installs five platform-default extensions into `public`
(`pgcrypto`, `uuid-ossp`, `pg_stat_statements`, `pg_net`, `supabase_vault`) that
weren't declared in the datasource block — undeclared, Prisma's drift detector
refuses to migrate at all (treats them as unexpected). Now declared alongside
`postgis`, matching what every Supabase project (local or hosted) actually has.

## Constraints (applied — `migrations/20260805181420_init/migration.sql`)

Prisma's schema language cannot express arbitrary `CHECK` constraints. The following
were added as a hand-written addition to the generated migration SQL
(`prisma migrate diff` to generate, then hand-appended before applying —
see `migrations/20260805181420_init/migration.sql`):

```sql
-- Favorite (ERD §3.16): exactly one of station_id / third_party_place_id is non-null.
ALTER TABLE favorite
  ADD CONSTRAINT favorite_polymorphic_target_xor
  CHECK (
    (station_id IS NOT NULL AND third_party_place_id IS NULL)
    OR (station_id IS NULL AND third_party_place_id IS NOT NULL)
  );

-- Review (ERD §3.15): same pattern.
ALTER TABLE review
  ADD CONSTRAINT review_polymorphic_target_xor
  CHECK (
    (station_id IS NOT NULL AND third_party_place_id IS NULL)
    OR (station_id IS NULL AND third_party_place_id IS NOT NULL)
  );

-- Review: rating must be 1-5 (ERD §3.15 "int, 1-5") — not enforceable via
-- Prisma's `Int` type alone.
ALTER TABLE review
  ADD CONSTRAINT review_rating_range
  CHECK (rating BETWEEN 1 AND 5);

-- Notification (Phase 4 additive gap-fill, confirmed with user 2026-08-05):
-- is_read/read_at must stay consistent — an unread notification always has
-- read_at = null, and a read one always has it set (matches the
-- Notification entity's own invariant, domain/entities/notification.entity.ts).
ALTER TABLE notification
  ADD CONSTRAINT notification_read_state_consistency
  CHECK (
    (is_read = false AND read_at IS NULL)
    OR (is_read = true AND read_at IS NOT NULL)
  );
```

These invariants are also still enforced at the Domain layer
(`domain/entities/favorite.entity.ts`, each module's own `review.entity.ts`) as
a second, independent guard — see ADR-0028's precedent — not only the DB `CHECK`.

## Indexes (applied — `migrations/20260805181420_init/migration.sql`)

`Station.position`/`ThirdPartyPlace.position` are `Unsupported("geography(Point, 4326)")`
columns (see the Station model's doc comment) — Prisma's migration engine cannot
manage indexes on `Unsupported` columns at all, so the GIST spatial indexes the
ERD calls for (§5 "idx_station_position", "idx_place_position" — what every
`ST_DWithin` nearby-search query, Facilities Pass 3, depends on for acceptable
performance at scale) were added by hand in the same first migration:

```sql
CREATE INDEX idx_station_position ON station USING GIST (position);
CREATE INDEX idx_place_position ON third_party_place USING GIST (position);
```

Without these, `searchNearby` in both `PrismaStationRepository` and
`PrismaThirdPartyPlaceRepository` would fall back to a sequential scan under
`ST_DWithin` — correct, but the `NFR-PERF-01` (≤1.5s) target this endpoint
exists to satisfy would not hold past a small row count. All other indexes
implicated by Phase 4's query patterns (`station.status`, `cabin.occupancy_status`,
`third_party_place.place_type`, `review.station_id`, `review.third_party_place_id`,
plus every FK Prisma indexes automatically via `@relation`) are already declared
directly in `schema.prisma` and need no manual migration step.

## Operations module (`telemetry_reading` partitioning)

[ADR-0013](../../../docs/adr/0013-time-series-storage-strategy.md) specifies
**native declarative range partitioning** on `telemetry_reading.recorded_at`
(monthly partitions, managed by `pg_partman` or a `pg_cron` job) — Prisma's
schema language cannot declare a partitioned table at all, so `schema.prisma`'s
`TelemetryReading` model is an ordinary (unpartitioned) table, including in
the first real migration (`migrations/20260805181420_init/`) — deliberately
out of scope for that migration (Release Validation's explicit scope was
"GIST indexes, CHECK/XOR constraints" only) and irrelevant at the row counts
this environment could ever produce (no IoT ingestion write path exists —
see the Known gaps section below). Converting it to a partitioned table by
hand remains a future migration:

```sql
-- Recreate telemetry_reading as a partitioned table (ADR-0013). Prisma's
-- migration engine cannot express PARTITION BY, so this must be authored
-- directly in the first hand-edited migration, same treatment as the GIST
-- indexes above.
-- (Illustrative only — exact DDL depends on whatever `prisma migrate dev`
-- generates for the initial CREATE TABLE, which this then supersedes.)
CREATE TABLE telemetry_reading (
  ...
) PARTITION BY RANGE (recorded_at);

CREATE TABLE telemetry_reading_2026_08 PARTITION OF telemetry_reading
  FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
-- subsequent months created ahead of need by pg_cron, per ADR-0013.
```

### Known gaps (flagged, not silently resolved)

- **No ingestion write path.** `TelemetryReadingRepository`
  (`src/modules/operations/domain/ports/telemetry-reading.repository.ts`) is
  read-only. Writing rows is Station Network's telemetry Anti-Corruption
  Layer per the Domain Model §1 context map (`SN -->|ACL| IOT_EXT`), fed by
  the IoT Platform — Master Roadmap Phase 9, entirely out of scope for every
  pass so far (not merely deferred like Access & Payment/Emergency/
  Sponsorship/Analytics). `telemetry_reading` is therefore expected to stay
  empty, and `GET /ops/stations`'s `batteryLevel`/`waterLevel` and
  `GET /ops/stations/{id}/occupancy-history` will correctly return
  null/empty until Phase 9 exists. The query logic itself is real and
  covered by unit tests against a mocked Prisma client — same treatment as
  Facilities' PostGIS queries, which also have no live database to run
  against (ADR-0016 hosting still Proposed).
- **No bounded-context owner in `domain-model.md`.** None of the documented
  10 bounded contexts list `TelemetryReading` as an owned entity — a real
  gap, distinct from (but same category as) the Review/Favorite gap already
  noted in Phase 4 Implementation Plan §12. Modeled under Operations because
  its only documented consumer endpoint (`GET /ops/stations/{id}/occupancy-history`)
  is tagged `Operations` and ADR-0013 ties it directly to FR-OPS-04.
- **`site_scope`-based filtering is not implemented.** `GET /ops/stations`'s
  openapi.yaml description says "scoped by site_scope", and ERD §3.7 defines
  `user_role.site_scope`, but no ERD entity or `schema.prisma` model defines
  a `Site` concept or a `station.site_id`/`site` column for that scope to
  filter against — `site_scope` is a free-form string with no documented
  station-side counterpart. `SiteScopeGuard` (identity module) only compares
  against a literal `:siteId` route parameter, which none of the `/ops/*`
  routes have, so it is a structural no-op here. `GET /ops/stations` and
  `GET /ops/alerts` therefore return the full, unscoped fleet/alert set.
  Flagged rather than inventing a `Site` entity not in the ERD.
- **FR-OPS-05 (role/site-scope administration) needed no new endpoint.**
  Neither `docs/api/openapi.yaml`'s `Operations` tag nor any other tag
  defines a role-management route. FR-OPS-05 is already satisfied by
  Identity Pass 1's `Role`/`UserRole` entities and its globally-wired
  `RolesGuard`/`SiteScopeGuard` — same "needed no new work" treatment
  Slatoki's FR-SLK-05 got from the already-shipped Facilities module.

## Access & Payment module (`migrations/20260806121959_access_payment/`)

Adds `AccessSession`, `Transaction`, and `IdempotencyKey` (ERD §3.10 plus one
additive gap-fill — see `IdempotencyKey`'s `schema.prisma` doc comment, same
"confirmed with the user" treatment as Notification's `is_read`/`read_at`
addition) and the `AccessSessionStatus`/`TransactionStatus` enums, backing
`AccessPaymentModule`.

**Generated during implementation without being applied live; applied and verified
during the subsequent implementation review.** A local Supabase stack
(`supabase start`, Docker) *is* running in this environment (unlike the
situation the module's original build instructions anticipated), so a normal
`prisma migrate dev` was attempted first. It failed with the same category of drift `schema.prisma`'s
datasource doc comment already describes for the five platform-default
extensions (`pg_stat_statements`, `pgcrypto`, `uuid-ossp` version/schema
metadata drift) and additionally proposed `prisma migrate reset` to
reconcile — a destructive, whole-database-dropping operation this pass was
not authorized to run against a shared local dev database. Instead, the
migration SQL was generated directly via:

```
npx prisma migrate diff --from-schema-datasource ./prisma/schema.prisma --to-schema-datamodel ./prisma/schema.prisma --script
```

(`--from-schema-datasource` introspects the *live* database directly rather
than requiring a shadow database, unlike `--from-migrations`, which needs
`--shadow-database-url`.) The generated script also proposed
`DROP INDEX "idx_station_position"` / `DROP INDEX "idx_place_position"` — a
false positive, not a real change: those two GIST indexes exist only because
they were hand-added to the first migration (see "## Indexes" above) for the
`Unsupported("geography(Point, 4326)")` columns Prisma's diff engine cannot
see declared anywhere in `schema.prisma`, so it proposes dropping what it
doesn't recognize. Both `DROP INDEX` statements were removed by hand from
`migrations/20260806121959_access_payment/migration.sql` before it was
saved — the same "hand-edit the generated SQL" precedent as the GIST
indexes/CHECK constraints in the first migration, just in the opposite
direction (protecting existing objects the diff engine doesn't know about,
rather than adding new ones it can't express).

The resulting `migration.sql` contains only additive `CREATE TYPE`/
`CREATE TABLE`/`CREATE INDEX`/`ALTER TABLE ... ADD CONSTRAINT` statements.
It was applied via `npx prisma migrate deploy` during the implementation
review and independently verified: `prisma migrate status` reports "Database
schema is up to date!", and `psql \d access_session` / `\d transaction` /
`\d idempotency_key` confirm the expected columns, foreign keys, and indexes
are live — including confirming both pre-existing GIST indexes
(`idx_station_position`, `idx_place_position`) survived intact. `npx prisma
generate` was also run successfully, so `@prisma/client`'s generated types
include `AccessSession`/`Transaction`/`IdempotencyKey` and compile/test
cleanly against the new repositories.

## Reviews management module (`migrations/20260806160431_reviews_management/`)

Adds `Review.updatedAt` (nullable, `@updatedAt`) — an additive gap-fill for
EPIC-05 US-05.2 ("manage my reviews": `PATCH`/`DELETE` on a review, plus
`GET /users/me/reviews`), confirmed with the user 2026-08-06. Not in the
original ERD §3.15 — same "flagged, not silently added" treatment as
`IdempotencyKey` / Notification's `is_read`/`read_at`.

Generated and applied in the same session, following the exact process the
Access & Payment migration's own README section above documents (docs
consulted before authoring this one). A local Supabase stack (`docker ps`
confirmed reachable — `supabase_db_supabase-local` on `127.0.0.1:54322`) was
already running. A normal `prisma migrate dev --name reviews_updated_at` was
attempted first; it failed with the same drift category already documented
above (`pg_stat_statements`/`pgcrypto`/`uuid-ossp` metadata drift) and
proposed `prisma migrate reset` to reconcile — not authorized, so it was not
run. Instead, the migration SQL was generated directly via:

```
npx prisma migrate diff --from-schema-datasource ./prisma/schema.prisma --to-schema-datamodel ./prisma/schema.prisma --script
```

This again proposed the same two false-positive `DROP INDEX
"idx_station_position"` / `DROP INDEX "idx_place_position"` statements
explained above (the diff engine still can't see the hand-added GIST
indexes anywhere in `schema.prisma`) — removed by hand before saving
`migrations/20260806160431_reviews_management/migration.sql`, which then
contains only `ALTER TABLE "review" ADD COLUMN "updated_at" TIMESTAMP(3);`.

Applied via `npx prisma migrate deploy` and independently verified:
`prisma migrate status` reports "Database schema is up to date!", and
`docker exec supabase_db_supabase-local psql -U postgres -d postgres -c '\d review'`
confirms the new nullable `updated_at` column alongside every pre-existing
column/index/constraint, and a follow-up query against `pg_indexes` confirms
both GIST indexes (`idx_station_position`, `idx_place_position`) survived
intact. `npx prisma generate` was also run successfully, so
`@prisma/client`'s generated `Review` type includes `updatedAt` and the full
test suite (unit + e2e) passes against it.

## Alpha environment migration

[`docs/deployment/alpha-environment.md`](../../../docs/deployment/alpha-environment.md)
introduces a minimal, non-production Alpha environment (real HTTPS backend
for mobile testers — not the Phase 3/13 production topology, and not a
resolution of ADR-0016). Every migration recorded above was authored and
applied against a **local** Supabase stack; none has been applied against a
hosted project, because none exists yet.

Once an Alpha Supabase project is provisioned (`alpha-environment.md` §3),
applying the existing `migrations/` directory to it needs no new authoring
— every migration in this directory is already the real, applied-and-verified
schema, just against `localhost` instead of a hosted `DATABASE_URL` so far.
The command is:

```
npx prisma migrate deploy
```

run with `DATABASE_URL` pointed at the Alpha project's connection string
(never `prisma migrate dev` against a hosted/shared database — that command
can create a shadow database and prompt for a destructive `migrate reset`,
neither appropriate outside a local, single-developer database). This
mirrors exactly how the Access & Payment and Reviews Management migrations
above were applied — `migrate deploy` is already this project's proven
apply-only, non-interactive command for a real database.

`npx prisma generate` must also be run wherever the backend is actually
built for Alpha (handled by `apps/backend/Dockerfile`'s build stage — see
`alpha-environment.md` §3 step 3) so the generated client's query-engine
binary matches that build's target platform, not whatever platform
generated it locally.
