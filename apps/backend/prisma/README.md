# Prisma schema notes

No live database is provisioned yet (ADR-0016 hosting is still Proposed; no Supabase
project has ever been deployed — see `docs/phase-4-implementation-plan.md`), so no
migration has been generated or run against a real Postgres instance. `schema.prisma`
has been validated with `npx prisma generate` (client generation, which only needs a
valid schema, not a live connection) but not with `npx prisma migrate dev` (which
needs one).

## Constraints to add once a live database exists

Prisma's schema language cannot express arbitrary `CHECK` constraints. The following
must be added as a hand-written SQL migration (`prisma migrate dev --create-only`,
then edit the generated `migration.sql`) the first time this schema is migrated
against a real database:

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

Until this migration exists, these invariants are enforced at the Domain layer
(`domain/entities/favorite.entity.ts`, each module's own `review.entity.ts`) as
the primary guard — see ADR-0028's precedent for documenting a real gap rather
than silently working around it.

## Indexes to add once a live database exists

`Station.position`/`ThirdPartyPlace.position` are `Unsupported("geography(Point, 4326)")`
columns (see the Station model's doc comment) — Prisma's migration engine cannot
manage indexes on `Unsupported` columns at all, so the GIST spatial indexes the
ERD calls for (§5 "idx_station_position", "idx_place_position" — what every
`ST_DWithin` nearby-search query, Facilities Pass 3, depends on for acceptable
performance at scale) must also be added by hand in the same first migration:

```sql
CREATE INDEX idx_station_position ON station USING GIST (position);
CREATE INDEX idx_place_position ON third_party_place USING GIST (position);
```

Without these, `searchNearby` in both `PrismaStationRepository` and
`PrismaThirdPartyPlaceRepository` falls back to a sequential scan under
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
`TelemetryReading` model is an ordinary (unpartitioned) table for now. The
first real migration must convert it by hand:

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

Until this exists, `telemetry_reading` is a normal table — correct, just not
partitioned, and irrelevant at the row counts this environment could ever
produce (see the ingestion gap below).

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
