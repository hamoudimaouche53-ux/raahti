# ADR-0009: Authentication & RBAC Strategy

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-07-31 |
| **Deciders** | Engineering team |
| **RAH-DOC-005 reference** | §4 ("gestion des accès et rôles pour les équipes multi-sites"), §9 ("authentification forte pour les tableaux de bord") |

## Context
RAH-DOC-005 requires optional accounts for end users (§2.6), strong authentication specifically for the Operator and Sponsor dashboards (§9), and multi-site role management for operations teams (§4). Supabase is the confirmed BaaS ([ADR-0005](./0005-baas-platform-supabase.md)).

## Decision
Use **Supabase Auth** as the identity provider for all account-holding users, layered with a **custom RBAC module** (Identity & Access bounded context, see [Domain Model §2](../architecture/domain-model.md#2-bounded-context-identity--access)) implementing the `role` / `user_role` model from the [ERD](../erd/erd.md#37-role--user-role-new--supports-fr-ops-05-nfr-sec-02): roles `usager`, `operateur` (with optional `site_scope`), `sponsor`, `admin`. Dashboard authentication (Operator, Sponsor) additionally requires the "strong authentication" posture of NFR-SEC-02 — at minimum enforced password policy plus MFA availability, exact mechanism to be finalized in Phase 1.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| Supabase Auth + custom RBAC (chosen) | Reuses confirmed BaaS; RBAC model matches multi-site requirement precisely | Custom RBAC logic must be maintained outside Supabase's built-in row-level-security policies unless RLS is also adopted |
| Third-party IdP (Auth0, Okta) | Mature enterprise RBAC/MFA tooling | Redundant with Supabase Auth already in the confirmed stack; added cost/integration surface |

## Consequences
### Positive
- End-user optional-account requirement (§2.6) and dashboard strong-auth requirement (§9) are both satisfiable from one identity provider.
- `site_scope` on `user_role` directly satisfies the multi-site requirement in §4 without a heavier multi-tenancy model.

### Negative / Trade-offs
- Exact MFA mechanism for dashboards is not yet finalized (Phase 1 item).

## Related
- [ERD §3.7](../erd/erd.md#37-role--user-role-new--supports-fr-ops-05-nfr-sec-02), [Domain Model §2](../architecture/domain-model.md#2-bounded-context-identity--access), [ADR-0005](./0005-baas-platform-supabase.md)
