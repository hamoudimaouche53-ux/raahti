import { Alert } from '../entities/alert.entity';
import { AlertStatus } from '../value-objects/alert-status.vo';

export const ALERT_REPOSITORY = Symbol('ALERT_REPOSITORY');

export interface AlertRepository {
  save(alert: Alert): Promise<void>;
  findById(id: string): Promise<Alert | null>;
  /** GET /ops/alerts (FR-OPS-02) — sorted severity DESC, then raisedAt ASC. Undefined status = no filter. */
  findAll(status?: AlertStatus): Promise<Alert[]>;
  /** Backs GET /ops/stations's `activeAlertCount` (FR-OPS-01) — count of non-resolved alerts, grouped by station. */
  countActiveGroupedByStation(): Promise<Map<string, number>>;
}
