import { DomainException } from '../../../../shared-kernel';

/** ERD §3.11. Transition graph enforced in domain/entities/alert.entity.ts. */
export type AlertStatus = 'open' | 'acknowledged' | 'in_progress' | 'resolved';

const VALID: readonly AlertStatus[] = ['open', 'acknowledged', 'in_progress', 'resolved'];

export class InvalidAlertStatusException extends DomainException {
  readonly code = 'OPERATIONS_INVALID_ALERT_STATUS';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized alert status (expected open|acknowledged|in_progress|resolved).`);
  }
}

export function assertAlertStatus(value: string): asserts value is AlertStatus {
  if (!VALID.includes(value as AlertStatus)) {
    throw new InvalidAlertStatusException(value);
  }
}
