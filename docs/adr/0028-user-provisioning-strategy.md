# ADR-0028: User Provisioning Strategy — JIT via Supabase `sub` as Primary Key

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-05 |
| **Deciders** | Engineering team + user (Phase 4 kickoff) |
| **RAH-DOC-005 reference** | N/A — Phase 4 implementation-level gap not addressed by any Phase 0/1 document |
| **Phase** | Phase 4 — Backend Implementation |

## Context

ADR-0009 and Security Architecture §1 establish Supabase Auth as the identity provider and specify how the API Backend *verifies* its JWTs, but neither document — nor any other Phase 0/1 document — specifies how a Supabase-authenticated principal becomes a row in RAHATI's own `user_account` table ([ERD §3.6](../erd/erd.md#36-user-account-src-ext)). This is a real gap, not an oversight to route around silently: `GET /users/me` (openapi.yaml, tag `Identity`) is the first endpoint that needs a `user_account` row to exist, and no mechanism for creating one had been decided. Flagged in [Phase 4 Implementation Plan §10](../phase-4-implementation-plan.md#10-status-update--bootstrap--module-1-identity--authentication-2026-08-05) and resolved with the user before implementing Identity Pass 2.

## Decision

1. **`user_account.id` is the Supabase Auth `sub` claim value**, not an independently generated UUID. This is the standard Supabase pattern (`public` schema tables keyed by `auth.users.id`) and avoids an undocumented extra mapping column with no ERD basis.
2. **Just-in-time (JIT) provisioning**: `GET /users/me` is the provisioning point. On each call, the backend performs a single atomic `INSERT ... ON CONFLICT (id) DO NOTHING`-equivalent (Prisma `upsert` with an empty `update` clause) keyed on `id = claims.sub`, populating `email`/`phone` from the verified JWT claims only on first insert. If the row already exists, the upsert's `update` branch is a no-op — it never overwrites fields (e.g. a previously-set `preferredLanguage`) on repeat calls.
3. Atomicity under concurrent first-requests (e.g. two devices logging in simultaneously) is guaranteed by Postgres's native `ON CONFLICT` handling of the upsert on the primary key — no application-level locking needed.
4. A unique-constraint violation on `email`/`phone` during the create branch (i.e. the claims' contact method already belongs to a *different* `id`) is caught and surfaced as a `409 Conflict` domain exception rather than a raw 500 — this is a genuine data-integrity conflict, not expected under normal operation.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| JIT on first `GET /users/me` (chosen) | No extra infrastructure; works entirely within the already-scoped NestJS backend; simple to test | Provisioning is implicit in a read endpoint rather than an explicit signup step |
| Supabase Auth webhook / Edge Function on user creation | Decoupled, provisions immediately at signup | Adds an infrastructure piece (webhook endpoint, Supabase-side Auth Hook configuration) not otherwise scoped for Phase 4; harder to test without a live Supabase project (none has ever been deployed — Phase 4 Implementation Plan context) |
| Independently generated `user_account.id` + separate `supabase_user_id` mapping column | Decouples internal ID from the auth provider's ID | Not supported by the ERD's current `user_account` shape (no such column); adds a lookup indirection with no documented requirement driving it |

## Consequences

### Positive
- Single atomic operation, race-safe by construction, no distributed-locking or read-then-write window.
- No schema change beyond what Pass 1 already defined (`user_account.id` was already a UUID primary key with no separate provisioning field required).

### Negative / Trade-offs
- Ties `user_account.id` permanently to the Supabase project's `auth.users.id` — migrating identity providers later would require a data migration mapping old to new IDs (accepted as out of V1 scope; no IdP migration is planned).
- A user who authenticates but never calls `GET /users/me` (or an equivalent authenticated endpoint) has no local profile row — acceptable since every authenticated mobile-app session calls `GET /users/me` on launch by convention (Phase 5 mobile implementation detail).

## Related
- [ADR-0009](./0009-authentication-and-rbac.md), [ERD §3.6](../erd/erd.md#36-user-account-src-ext), [Phase 4 Implementation Plan](../phase-4-implementation-plan.md)
