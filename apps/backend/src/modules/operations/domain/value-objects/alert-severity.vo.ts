import { DomainException } from '../../../../shared-kernel';

/**
 * ERD §3.11. Set once at `AlertRaised` and immutable thereafter (Domain Model
 * §10 invariant) — priority ordering for FR-OPS-02's alert queue is enforced
 * at the query layer via `ALERT_SEVERITY_RANK`, not by mutating this field.
 */
export type AlertSeverity = 'critical' | 'high' | 'medium' | 'low';

const VALID: readonly AlertSeverity[] = ['critical', 'high', 'medium', 'low'];

/** Higher rank sorts first. Backs openapi.yaml's `/ops/alerts` note: "Sort order: severity DESC (fire/SOS first)". */
export const ALERT_SEVERITY_RANK: Readonly<Record<AlertSeverity, number>> = {
  critical: 4,
  high: 3,
  medium: 2,
  low: 1,
};

export class InvalidAlertSeverityException extends DomainException {
  readonly code = 'OPERATIONS_INVALID_ALERT_SEVERITY';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized alert severity (expected critical|high|medium|low).`);
  }
}

export function assertAlertSeverity(value: string): asserts value is AlertSeverity {
  if (!VALID.includes(value as AlertSeverity)) {
    throw new InvalidAlertSeverityException(value);
  }
}
