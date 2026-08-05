import { DomainException } from '../../../../shared-kernel';

/** ERD §3.12. */
export type InterventionType = 'refill' | 'emptying' | 'repair' | 'preventive';

const VALID: readonly InterventionType[] = ['refill', 'emptying', 'repair', 'preventive'];

export class InvalidInterventionTypeException extends DomainException {
  readonly code = 'OPERATIONS_INVALID_INTERVENTION_TYPE';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized intervention type (expected refill|emptying|repair|preventive).`);
  }
}

export function assertInterventionType(value: string): asserts value is InterventionType {
  if (!VALID.includes(value as InterventionType)) {
    throw new InvalidInterventionTypeException(value);
  }
}
