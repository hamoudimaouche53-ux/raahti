import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';

/**
 * Restricts a route to the given roles (ADR-0009 RBAC model: usager|operateur|sponsor|admin,
 * ERD §3.7 role.code). Takes plain strings, not identity/'s branded RoleCode type — this
 * decorator is cross-cutting (platform/) and no module besides identity/ may import
 * identity/'s domain types (module-dependency-diagram.md §3).
 */
export const Roles = (...roles: string[]): MethodDecorator & ClassDecorator => SetMetadata(ROLES_KEY, roles);
