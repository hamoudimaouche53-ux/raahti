import { DomainException } from '../../../../shared-kernel';

/** Domain Model §6. Transition graph enforced in domain/entities/access-session.entity.ts. */
export type AccessSessionStatus = 'initiated' | 'payment_pending' | 'unlocked' | 'in_use' | 'completed' | 'cancelled';

const VALID: readonly AccessSessionStatus[] = [
  'initiated',
  'payment_pending',
  'unlocked',
  'in_use',
  'completed',
  'cancelled',
];

export class InvalidAccessSessionStatusException extends DomainException {
  readonly code = 'ACCESS_PAYMENT_INVALID_ACCESS_SESSION_STATUS';
  readonly status = 400;

  constructor(value: string) {
    super(
      `"${value}" is not a recognized access session status (expected initiated|payment_pending|unlocked|in_use|completed|cancelled).`,
    );
  }
}

export function assertAccessSessionStatus(value: string): asserts value is AccessSessionStatus {
  if (!VALID.includes(value as AccessSessionStatus)) {
    throw new InvalidAccessSessionStatusException(value);
  }
}
