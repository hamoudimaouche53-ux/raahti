import { DomainException } from '../../../../shared-kernel';
import { AlertSeverity } from '../value-objects/alert-severity.vo';
import { AlertStatus } from '../value-objects/alert-status.vo';
import { AlertType } from '../value-objects/alert-type.vo';

export class InvalidAlertStatusTransitionException extends DomainException {
  readonly code = 'OPERATIONS_INVALID_ALERT_STATUS_TRANSITION';
  readonly status = 400;

  constructor(from: AlertStatus, to: AlertStatus) {
    super(`Cannot transition an alert from "${from}" to "${to}".`);
  }
}

export interface AlertProps {
  id: string;
  stationId: string;
  type: AlertType;
  severity: AlertSeverity;
  status: AlertStatus;
  acknowledgedBy: string | null;
  raisedAt: Date;
  resolvedAt: Date | null;
}

/**
 * Aggregate root of the Operations bounded context (Domain Model §10).
 *
 * `raise()` has no HTTP entry point in openapi.yaml (only `GET /ops/alerts`
 * and `PATCH /ops/alerts/{id}` are documented) — flagged, not silently
 * assumed: alert creation is expected to originate from the IoT telemetry
 * Anti-Corruption Layer (Domain Model §1 context map: `SN -->|ACL| IOT_EXT`)
 * or a future Emergency Mode SOS trigger, neither of which exists yet
 * (IoT Platform is Master Roadmap Phase 9, entirely out of this pass's
 * scope). This method exists for domain completeness/testability and for
 * a future publisher to call, exactly like Notifications' `queue()` was
 * built ahead of a real event publisher.
 *
 * Status transition graph (open -> acknowledged -> {in_progress, resolved}
 * -> resolved) is a judgment call: neither the ERD, domain-model.md, nor
 * openapi.yaml specify the graph beyond the 4 status values and
 * `AlertUpdateRequest`'s allowed target values (acknowledged|in_progress|
 * resolved). Requiring acknowledgement before any further transition
 * reflects "someone looked at it before it moves" and is deliberately
 * conservative — flagged rather than invented silently.
 */
export class Alert {
  private static readonly TRANSITIONS: Readonly<Record<AlertStatus, readonly AlertStatus[]>> = {
    open: ['acknowledged'],
    acknowledged: ['in_progress', 'resolved'],
    in_progress: ['resolved'],
    resolved: [],
  };

  private constructor(private props: AlertProps) {}

  static raise(params: { id: string; stationId: string; type: AlertType; severity: AlertSeverity }): Alert {
    return new Alert({
      id: params.id,
      stationId: params.stationId,
      type: params.type,
      severity: params.severity,
      status: 'open',
      acknowledgedBy: null,
      raisedAt: new Date(),
      resolvedAt: null,
    });
  }

  static restore(props: AlertProps): Alert {
    return new Alert(props);
  }

  /** PATCH /ops/alerts/{id} — status -> acknowledged|in_progress|resolved (FR-OPS-02). */
  updateStatus(next: AlertStatus, operatorId: string): void {
    const allowed = Alert.TRANSITIONS[this.props.status];
    if (!allowed.includes(next)) {
      throw new InvalidAlertStatusTransitionException(this.props.status, next);
    }
    this.props = {
      ...this.props,
      status: next,
      acknowledgedBy: next === 'acknowledged' ? operatorId : this.props.acknowledgedBy,
      resolvedAt: next === 'resolved' ? new Date() : this.props.resolvedAt,
    };
  }

  get id(): string {
    return this.props.id;
  }

  get stationId(): string {
    return this.props.stationId;
  }

  get type(): AlertType {
    return this.props.type;
  }

  get severity(): AlertSeverity {
    return this.props.severity;
  }

  get status(): AlertStatus {
    return this.props.status;
  }

  get acknowledgedBy(): string | null {
    return this.props.acknowledgedBy;
  }

  get raisedAt(): Date {
    return this.props.raisedAt;
  }

  get resolvedAt(): Date | null {
    return this.props.resolvedAt;
  }

  /** Backs GET /ops/stations's `activeAlertCount` (FR-OPS-01) — everything short of resolved. */
  get isActive(): boolean {
    return this.props.status !== 'resolved';
  }
}
