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
```

The same pattern applies to `Review` (ERD §3.15) once it is modeled (facilities
module, Phase 4 Implementation Plan §6 item 3) — `review_polymorphic_target_xor`
with the same shape, substituting the Review table/columns.

Until this migration exists, the invariant is enforced at the Domain layer
(`domain/entities/favorite.entity.ts`) as the primary guard — see ADR-0028's
precedent for documenting a real gap rather than silently working around it.
