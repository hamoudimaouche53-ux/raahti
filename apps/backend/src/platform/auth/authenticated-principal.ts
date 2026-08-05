/**
 * The shape attached to `request.user` by JwtAuthGuard (identity module) once
 * a Supabase-issued JWT is verified — the cross-cutting contract every
 * module's controllers rely on via `@CurrentUser()`. Lives in `platform/`
 * (not `identity/`) because every module needs it, and the module-dependency
 * matrix (module-dependency-diagram.md §3) grants no module a sanctioned
 * dependency on IdentityModule — only `platform/`/`shared-kernel/` are
 * universally depended-upon. Identity's own JWT-verification-layer type
 * (`identity/infrastructure/auth/jwt-claims.ts`) is built on top of this.
 */
export interface AuthenticatedPrincipal {
  sub: string;
  email?: string;
  phone?: string;
  /** RBAC role code (ADR-0009) — kept as a plain string here; identity/ refines it to its own RoleCode union internally. */
  role?: string;
  site_scope?: string;
  /** Supabase authentication assurance level — "aal2" once MFA/TOTP is verified. */
  aal?: string;
  exp: number;
  iat: number;
}
