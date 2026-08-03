# API Architecture

| | |
|---|---|
| **Document ID** | RAH-DOC-023-API-ARCHITECTURE |
| **Phase** | Phase 1 — System Architecture |
| **Version** | 1.0 |
| **Related** | [System Architecture Document](../architecture/system-architecture.md) · [OpenAPI Contract](./openapi.yaml) · [ADR-0007 — REST](../adr/0007-api-style-rest.md) · [ADR-0012](../adr/0012-backend-framework-selection.md) |

## 1. Principle: API-First, Contract Before Code
[`openapi.yaml`](./openapi.yaml) in this folder is the **reviewed, authoritative contract**. Phase 4 controller implementation must match it; `@nestjs/swagger`-generated output is checked against it in CI (contract-diff check), not the other way around. Any endpoint change requires an `openapi.yaml` PR reviewed like any other architecture change.

## 2. Versioning
- URL-path versioning: `/v1/...`. A breaking change ships as `/v2/...` alongside `/v1/...` for a documented deprecation window (minimum 6 months, tracked in a future `docs/api/CHANGELOG.md` once implementation begins).
- Non-breaking additions (new optional fields, new endpoints) do not bump the version.

## 3. Authentication & Authorization
- **AuthN**: Bearer JWT issued by Supabase Auth ([ADR-0009](../adr/0009-authentication-and-rbac.md)), passed as `Authorization: Bearer <token>`. Public, unauthenticated endpoints (map/place discovery, per FR-USR-01's optional-account principle) are explicitly marked `security: []` in the OpenAPI file.
- **AuthZ**: role claims (`usager`, `operateur`, `sponsor`, `admin`) embedded in the JWT (custom claim, set at role-grant time) are checked by a NestJS `RolesGuard` per endpoint. Operator endpoints additionally check `site_scope` from [ERD §3.7](../erd/erd.md#37-role--user-role-new--supports-fr-ops-05-nfr-sec-02) against the requested station's site. Full detail in [Security Architecture](../architecture/security-architecture.md).

## 4. Request/Response Conventions
- JSON request/response bodies, `Content-Type: application/json`.
- Field naming: `camelCase` in JSON payloads (mapped from the ERD's `snake_case` columns at the Infrastructure/Interface boundary).
- Timestamps: ISO 8601 UTC (`2026-07-31T10:00:00Z`).
- Money: `{ "amount": "150.00", "currency": "DZD" }` — amount as a **string** to avoid floating-point rounding errors in transport.
- Geo position: GeoJSON `{ "type": "Point", "coordinates": [lng, lat] }` (GeoJSON's lng-lat order, matching PostGIS convention).

## 5. Bilingual Content (FR/AR, NFR-I18N-01)
- Bilingual fields (place/station names, tag labels) are returned as an object: `{ "fr": "...", "ar": "..." }` — never as a single language-negotiated string — so the client always has both and switches instantly on the in-app language toggle (FR-I18N-01) without a re-fetch.
- `Accept-Language` header is honored only for **system-generated** content (error messages, validation messages), not for natively-authored bilingual entity fields, which are always returned in both languages per the object convention above.

## 6. Pagination
- Cursor-based pagination for all list endpoints (`?cursor=...&limit=...`), chosen over offset-based because the primary list use case (nearby places, FR-MAP-01) is a spatially-ordered, frequently-changing result set where offset pagination would produce duplicate/skipped results as occupancy changes between pages.
- Response envelope: `{ "data": [...], "nextCursor": "..." | null }`.

## 7. Error Schema
Follows **RFC 7807 (`application/problem+json`)**:
```json
{
  "type": "https://raahti.dev/errors/cabin-unavailable",
  "title": "Cabin is no longer available",
  "status": 409,
  "detail": "Cabin C-014 at station ST-002 transitioned to occupied before payment could complete.",
  "instance": "/v1/access-sessions/9f2e...",
  "code": "ACCESS_SESSION_CABIN_UNAVAILABLE"
}
```
- `code` is a stable, machine-readable identifier (used by the mobile app for localized error copy — see [Cross-Cutting Architecture — Error Handling](../architecture/cross-cutting-architecture.md#error-handling)), distinct from the HTTP status and from the human-readable `title`/`detail` (which are always in the request's negotiated system language per §5).

## 8. Idempotency
- All state-changing payment endpoints (`POST /v1/access-sessions`, `POST /v1/access-sessions/{id}/payments`) require an `Idempotency-Key` header. The backend deduplicates on `(user, key)` for a rolling 24h window, preventing double-charge on client retry — directly mitigating Risk R-11/R-12 (unlock/payment reliability under flaky station or client connectivity).

## 9. Rate Limiting
- Per-user/IP token-bucket limiting at the API/Interface layer (NestJS guard), tuned per endpoint class: generous for read endpoints (map/place queries), strict for payment-initiation endpoints. Exact thresholds are a Phase 4 tuning exercise; the architectural hook (a `RateLimitGuard` applied via decorator) is fixed now.

## 10. Real-Time Channels (non-REST)
Real-time cabin/alert updates (FR-PAY-05, FR-OPS-01) use **Supabase Realtime** (Postgres logical replication over WebSocket), not polling REST endpoints. Channel naming convention: `station:{stationId}:cabins`, `ops:alerts`. This is documented here because it is part of the public client-facing contract even though it is not an HTTP endpoint; see [Data Flow Diagrams](../architecture/data-flow-diagrams.md) for the full path from IoT telemetry to Realtime broadcast.

## 11. Internal (Non-Public) Contracts
The IoT ingestion service's inbound path (MQTT topic → internal webhook into `StationNetworkModule`) is **not** part of the public API surface and is not in `openapi.yaml` — it is an internal integration contract, documented in [Data Flow Diagrams](../architecture/data-flow-diagrams.md) instead, per RAH-DOC-005 §7's "webhooks vers le backend applicatif."

## 12. OpenAPI Contract Coverage
[`openapi.yaml`](./openapi.yaml) covers the V1-critical endpoint surface (traced to SRS `FR-*` IDs in the OpenAPI `description` field of each operation): Identity/profile, Places/Map, Slatoki, Emergency, Access & Payment, Operator Dashboard, Sponsor Dashboard, Notifications. It intentionally does **not** yet include V2/V3-scoped endpoints (loyalty program, third-party self-declaration API) per [PRD §13 — Out of Scope](../prd/PRD.md#13-out-of-scope-v1).

## 13. Assumptions
- JWT custom-claim role embedding (§3) assumes Supabase Auth's custom-claims/hook mechanism is used to inject `role`/`site_scope` at token-issuance time — a Phase 4 implementation detail consistent with [ADR-0009](../adr/0009-authentication-and-rbac.md).

## 14. Open Questions
- Exact rate-limit thresholds (§9) — Phase 4 tuning.
- API deprecation-window governance process — to be formalized when `/v2` first becomes necessary.

## 15. Completion Status

| Item | Status |
|---|---|
| Versioning, auth, error, pagination conventions specified | ✅ Complete |
| Bilingual content contract specified | ✅ Complete |
| Idempotency/rate-limiting hooks specified | ✅ Complete |
| OpenAPI contract authored for V1 surface | ✅ Complete — see [openapi.yaml](./openapi.yaml) |

**Phase 1 deliverable 4 of 10 — API Architecture: COMPLETE.**
