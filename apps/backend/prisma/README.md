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
