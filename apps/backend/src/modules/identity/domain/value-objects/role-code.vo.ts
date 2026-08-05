import { DomainException } from '../../../../shared-kernel';

export type RoleCode = 'usager' | 'operateur' | 'sponsor' | 'admin';

const VALID_ROLE_CODES: readonly RoleCode[] = ['usager', 'operateur', 'sponsor', 'admin'];

export class InvalidRoleCodeException extends DomainException {
  readonly code = 'IDENTITY_INVALID_ROLE_CODE';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized role (expected usager|operateur|sponsor|admin).`);
  }
}

/** ERD §3.7 role.code — Domain Model §2/ADR-0009's 4 fixed RBAC roles. */
export function assertRoleCode(value: string): asserts value is RoleCode {
  if (!VALID_ROLE_CODES.includes(value as RoleCode)) {
    throw new InvalidRoleCodeException(value);
  }
}

export function isRoleCode(value: string): value is RoleCode {
  return VALID_ROLE_CODES.includes(value as RoleCode);
}
