import { Role } from '../entities/role.entity';
import { RoleCode } from '../value-objects/role-code.vo';

export const ROLE_REPOSITORY = Symbol('ROLE_REPOSITORY');

export interface RoleRepository {
  findByCode(code: RoleCode): Promise<Role | null>;
  list(): Promise<Role[]>;
}
