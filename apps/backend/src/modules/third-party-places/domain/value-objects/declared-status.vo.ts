import { DomainException } from '../../../../shared-kernel';

export type DeclaredStatus = 'open' | 'closed' | 'unknown';
export type StatusSource = 'community' | 'owner_declared';

const VALID_STATUS: readonly DeclaredStatus[] = ['open', 'closed', 'unknown'];
const VALID_SOURCE: readonly StatusSource[] = ['community', 'owner_declared'];

export class InvalidDeclaredStatusException extends DomainException {
  readonly code = 'THIRD_PARTY_PLACES_INVALID_DECLARED_STATUS';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized declared status (expected open|closed|unknown).`);
  }
}

export class InvalidStatusSourceException extends DomainException {
  readonly code = 'THIRD_PARTY_PLACES_INVALID_STATUS_SOURCE';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized status source (expected community|owner_declared).`);
  }
}

export function assertDeclaredStatus(value: string): asserts value is DeclaredStatus {
  if (!VALID_STATUS.includes(value as DeclaredStatus)) {
    throw new InvalidDeclaredStatusException(value);
  }
}

export function assertStatusSource(value: string): asserts value is StatusSource {
  if (!VALID_SOURCE.includes(value as StatusSource)) {
    throw new InvalidStatusSourceException(value);
  }
}
