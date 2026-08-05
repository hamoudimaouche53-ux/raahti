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
