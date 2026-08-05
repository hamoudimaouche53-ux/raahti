import { DomainException } from '../../../../shared-kernel';

/** ERD §3.11. Mirrors FR-OPS-02's priority order (fire/SOS -> technical_anomaly -> preventive_maintenance). */
export type AlertType = 'fire' | 'sos' | 'technical_anomaly' | 'preventive_maintenance';

const VALID: readonly AlertType[] = ['fire', 'sos', 'technical_anomaly', 'preventive_maintenance'];

export class InvalidAlertTypeException extends DomainException {
  readonly code = 'OPERATIONS_INVALID_ALERT_TYPE';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized alert type (expected fire|sos|technical_anomaly|preventive_maintenance).`);
  }
}

export function assertAlertType(value: string): asserts value is AlertType {
  if (!VALID.includes(value as AlertType)) {
    throw new InvalidAlertTypeException(value);
  }
}
