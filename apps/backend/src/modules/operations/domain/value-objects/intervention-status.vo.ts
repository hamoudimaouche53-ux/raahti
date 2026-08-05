import { DomainException } from '../../../../shared-kernel';

/** ERD §3.12. Transition graph enforced in domain/entities/maintenance-intervention.entity.ts. */
export type InterventionStatus = 'scheduled' | 'in_progress' | 'completed' | 'cancelled';

const VALID: readonly InterventionStatus[] = ['scheduled', 'in_progress', 'completed', 'cancelled'];

export class InvalidInterventionStatusException extends DomainException {
  readonly code = 'OPERATIONS_INVALID_INTERVENTION_STATUS';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized intervention status (expected scheduled|in_progress|completed|cancelled).`);
  }
}

export function assertInterventionStatus(value: string): asserts value is InterventionStatus {
  if (!VALID.includes(value as InterventionStatus)) {
    throw new InvalidInterventionStatusException(value);
  }
}
