# Security Architecture

| | |
|---|---|
| **Document ID** | RAH-DOC-026-SECURITY-ARCHITECTURE |
| **Phase** | Phase 1 — System Architecture |
| **Version** | 1.0 |
| **Related** | [ADR-0009 — Auth/RBAC](../adr/0009-authentication-and-rbac.md) · [ADR-0014 — Payment Abstraction](../adr/0014-payment-provider-abstraction.md) · [SRS §8.3](../srs/SRS.md#83-security--privacy-9) · [ERD](../erd/erd.md) |

## 1. Authentication (AuthN)

- **Identity provider**: Supabase Auth ([ADR-0005](../adr/0005-baas-platform-supabase.md), [ADR-0009](../adr/0009-authentication-and-rbac.md)). Supports email/password and phone/OTP, matching RAH-DOC-005 §2.6's optional-account model (`email`/`phone` both nullable, [ERD §3.6](../erd/erd.md#36-user-account-src-ext)).
- **Tokens**: short-lived JWT access token + refresh token (Supabase default rotation). Access token embeds custom claims `role` and `site_scope` (set at role-grant time via a Supabase Auth hook/Edge Function), consumed by the API Backend's `AuthGuard`.
- **Dashboard "strong authentication"** (NFR-SEC-02): Operator and Sponsor Dashboards additionally require **MFA (TOTP)** enabled on the Supabase Auth account before dashboard-role JWTs are issued — enforced by a `RequireMfaGuard` on all `/ops/*` and `/sponsors/*` routes with `role != usager`.
- **Guest usage**: read-only public endpoints (`/places/nearby`, `/stations/{id}`, `/slatoki/places`) are marked `security: []` in the OpenAPI contract and require no token, per FR-USR-01.

## 2. Authorization (AuthZ)

- **RBAC model**: `role` (`usager`, `operateur`, `sponsor`, `admin`) and `user_role.site_scope` per [ERD §3.7](../erd/erd.md#37-role--user-role-new--supports-fr-ops-05-nfr-sec-02).
- **Two-layer enforcement** (defense in depth):
  1. **Application layer**: NestJS `RolesGuard` + `SiteScopeGuard` on every controller route, checked against JWT claims — the primary, testable enforcement point.
  2. **Database layer**: Postgres **Row-Level Security (RLS)** policies on Supabase tables as a second, independent barrier — e.g. an `operateur` role's Postgres session can only `SELECT`/`UPDATE` `station`/`cabin`/`alert` rows where `site_scope` matches, even if an application-layer bug were to omit the guard. RLS policy definitions are a Phase 4 implementation task; the requirement that every table with tenant/role-sensitive data **must** have an RLS policy (not just an app-layer check) is fixed here as a non-negotiable architectural rule.
- **Sponsor isolation** (FR-SPN-04): RLS + a dedicated read-only Postgres role for `SponsorshipModule` queries ensures sponsor-facing queries are structurally incapable of joining to `user_account` — enforced at the database grant level, not only application logic (see [Domain Model §9 invariant](./domain-model.md#9-bounded-context-sponsorship)).

## 3. Encryption

- **In transit**: TLS 1.2+ enforced on all public endpoints (HSTS header on API responses); MQTT connections use TLS (`mqtts://`) between station gateways and the broker.
- **At rest**: Supabase-managed Postgres encryption at rest (AES-256, platform-provided); Supabase Storage objects (verification documents, place photos) encrypted at rest by the platform.
- **Payment data**: no raw card data ever reaches RAHATI infrastructure — `payment_method.provider_ref` and `transaction.provider_ref` store only opaque provider tokens ([ADR-0014](../adr/0014-payment-provider-abstraction.md)), keeping PCI-DSS scope minimal regardless of eventual provider (SAQ A / SAQ A-EP territory, to be confirmed once a provider is selected).

## 4. Secrets Management

- No secret (API keys, database credentials, JWT signing keys, MQTT broker credentials) is committed to the repository at any point — enforced via `.gitignore` + a pre-commit secret-scan hook (Phase 3 CI setup).
- Runtime secrets are injected via environment variables from the hosting platform's secret store (exact mechanism depends on [ADR-0016](../adr/0016-hosting-provider-selection.md)'s eventual provider — AWS Secrets Manager / OVHcloud equivalent / platform env-var vault).

## 5. Input Validation & API Hardening

- All request DTOs validated via `class-validator` at the Interface layer (NestJS `ValidationPipe`, whitelist mode — unknown fields rejected) before reaching the Application layer — no unvalidated input ever reaches a use case.
- PostGIS spatial query parameters (`lat`/`lng`/`radiusMeters`) are range-validated to prevent resource-exhaustion queries (`radiusMeters` capped at 20,000m per [openapi.yaml](../api/openapi.yaml)).
- Standard API hardening: CORS allowlist (mobile app origin exempt via native HTTP, web/dashboard origins explicitly listed), rate limiting ([ADR-0015](../adr/0015-caching-strategy.md) adjacent — see [API Architecture §9](../api/api-architecture.md#9-rate-limiting)), `Idempotency-Key` on payment endpoints ([API Architecture §8](../api/api-architecture.md#8-idempotency)).

## 6. Privacy & Compliance (NFR-SEC-04)

- **Data minimization**: Sponsor Dashboard queries are aggregate-only by construction (§2). Operator Dashboard has no access to end-user PII beyond what an active `access_session`/`alert` requires operationally.
- **Retention**: `telemetry_reading` partitions ([ADR-0013](../adr/0013-time-series-storage-strategy.md)) are rolled off per the policy in [Deployment Architecture](../deployment/deployment-architecture.md#backup--retention); `verification_document` retention/deletion policy is a compliance item pending legal review (Risk R-13).
- **Local regulation**: full compliance mapping against Algerian personal-data-protection law is explicitly out of this architecture's authority — flagged as Risk R-13, requiring legal review before Phase 4/13 sign-off, consistent with the Phase 0 Risk Register.

## 7. Audit Logging

- `NotificationsModule` and a dedicated audit-log writer subscribe to all domain events touching `Transaction`, `AccessSession`, `Alert`, and `VerificationDocument` state changes, per RAH-DOC-005 §6's "journalisation complète" requirement (FR-CLD-04) — append-only, no update/delete permitted on audit rows (enforced via RLS: no `UPDATE`/`DELETE` grant on the audit table for any application role).

## 8. Threat Model Summary (STRIDE — critical flows only)

| Flow | Threat | Mitigation |
|---|---|---|
| Access & Payment | **Spoofing**: forged QR code / replayed unlock request | QR codes are per-cabin, server-validated against live `cabin` state; `Idempotency-Key` + short QR validity window (Phase 4 tuning) |
| Access & Payment | **Repudiation**: user disputes a charge | Full `transaction` audit trail (§7), provider-side transaction ID stored (`provider_ref`) |
| Access & Payment | **Information Disclosure**: payment token leak | Tokens only, never raw PAN (§3); RLS restricts `payment_method` rows to their owning `user_id` |
| Auth | **Elevation of Privilege**: role/site_scope tampering | Claims are server-signed (JWT), not client-supplied; RLS is claim-derived, not request-body-derived |
| Sponsor Dashboard | **Information Disclosure**: PII leak via aggregate query bug | Dedicated read-only DB role with no grant on `user_account` (§2) — structural, not just logical, prevention |
| IoT Ingestion | **Tampering**: forged station telemetry | MQTT client-certificate authentication per station gateway (Phase 3 provisioning item); ingestion service validates station identity against `station.code` before accepting telemetry |

Full threat-modeling workshop (all flows, formal STRIDE/DREAD scoring) is a recommended Phase 4 kickoff activity, not repeated in full here.

## 9. Assumptions
- MFA enforcement for dashboards assumes Supabase Auth's TOTP support is sufficient; a dedicated enterprise IdP was evaluated and rejected in [ADR-0009](../adr/0009-authentication-and-rbac.md) for cost/complexity reasons at V1 scale.
- RLS policy authoring is a Phase 4 implementation task; this document fixes the *requirement* that every sensitive table has one, not the policy SQL itself.

## 10. Open Questions
- PCI-DSS SAQ level depends on the eventual payment provider's integration model (redirect vs. embedded) — cannot be finalized until [ADR-0014](../adr/0014-payment-provider-abstraction.md)'s deferred provider decision is made.
- Local data-protection legal review (Risk R-13) — pending.

## 11. Completion Status

| Item | Status |
|---|---|
| AuthN/AuthZ architecture specified | ✅ Complete |
| Encryption, secrets management specified | ✅ Complete |
| PCI-DSS-aligned payment isolation specified | ✅ Complete (provider-agnostic) |
| Threat model summary for critical flows | ✅ Complete (full workshop deferred to Phase 4) |
| Legal/compliance review of local data-protection law | ⚠️ Pending (Risk R-13) |

**Phase 1 deliverable 7 of 10 — Security Architecture: COMPLETE.**
