import { AuthenticatedPrincipal } from '../../../../platform/auth';
import { RoleCode } from '../../domain/value-objects/role-code.vo';

/**
 * Shape of a verified Supabase Auth JWT payload, as consumed by the API Backend's
 * guards (security-architecture.md §1–2, ADR-0009). `role`/`site_scope` are the
 * custom claims set at role-grant time via a Supabase Auth hook/Edge Function.
 * Refines platform/'s cross-cutting `AuthenticatedPrincipal` contract with
 * identity/'s own branded `RoleCode` type for internal (guard/repository) use.
 *
 * KNOWN INTEGRATION RISK (flagged, not silently resolved): Supabase reserves a
 * top-level `role` claim for its own Postgres role (typically "authenticated"),
 * which may collide with the custom `role` claim name the docs specify verbatim.
 * This can only be confirmed once a real Supabase project's Auth Hook is
 * configured (no backend has ever been deployed — Phase 4 Implementation Plan
 * context) — implemented literally per the docs for now.
 */
export interface JwtClaims extends Omit<AuthenticatedPrincipal, 'role'> {
  role?: RoleCode;
}
