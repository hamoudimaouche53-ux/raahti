import { RoleCode } from '../value-objects/role-code.vo';

/** ERD §3.7 — lookup entity for the 4 fixed RBAC roles (Domain Model §2). */
export class Role {
  constructor(
    readonly id: string,
    readonly code: RoleCode,
    readonly labelFr: string,
    readonly labelAr: string,
  ) {}
}
