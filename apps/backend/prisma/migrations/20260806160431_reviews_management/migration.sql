-- NOTE: `prisma migrate diff` also proposed `DROP INDEX "idx_station_position"`
-- and `DROP INDEX "idx_place_position"` here — a false positive, not a real
-- schema change. Those two GIST indexes were added by hand in
-- migrations/20260805181420_init/migration.sql (see prisma/README.md
-- "Indexes") because they sit on `Unsupported("geography(Point, 4326)")`
-- columns Prisma's migration engine cannot manage at all; the diff engine
-- only sees "declared in the live DB, absent from schema.prisma" and
-- proposes dropping them. Removed by hand from this migration, same
-- precedent as the init and access_payment migrations' own hand-edits.

-- AlterTable
-- EPIC-05 US-05.2 ("manage my reviews") — additive gap-fill, not in the
-- original ERD §3.15, confirmed with the user 2026-08-06 (same treatment as
-- IdempotencyKey / Notification's is_read/read_at). Nullable: never set
-- until the first PATCH /places/{placeType}/{placeId}/reviews/{reviewId};
-- `@updatedAt` auto-manages it on every subsequent save().
ALTER TABLE "review" ADD COLUMN     "updated_at" TIMESTAMP(3);
