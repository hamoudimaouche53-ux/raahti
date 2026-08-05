import { SetMetadata } from '@nestjs/common';
import { RoleCode } from '../../domain/value-objects/role-code.vo';

export const ROLES_KEY = 'roles';

/** Restricts a route to the given roles (ADR-0009 RBAC model). */
export const Roles = (...roles: RoleCode[]): MethodDecorator & ClassDecorator => SetMetadata(ROLES_KEY, roles);
