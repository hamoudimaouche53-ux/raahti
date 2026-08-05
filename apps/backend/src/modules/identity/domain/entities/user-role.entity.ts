/** ERD §3.7 — grants a Role to a User, optionally scoped to a site (multi-site operateur, RAH-DOC-005 §4). */
export class UserRole {
  constructor(
    readonly id: string,
    readonly userId: string,
    readonly roleId: string,
    readonly siteScope: string | null,
    readonly grantedAt: Date,
  ) {}
}
