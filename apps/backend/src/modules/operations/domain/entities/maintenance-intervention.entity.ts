import { DomainException } from '../../../../shared-kernel';
import { InterventionStatus } from '../value-objects/intervention-status.vo';
import { InterventionType } from '../value-objects/intervention-type.vo';

export class InvalidInterventionStatusTransitionException extends DomainException {
  readonly code = 'OPERATIONS_INVALID_INTERVENTION_STATUS_TRANSITION';
  readonly status = 400;

  constructor(from: InterventionStatus, to: InterventionStatus) {
    super(`Cannot transition a maintenance intervention from "${from}" to "${to}".`);
  }
}

export interface MaintenanceInterventionProps {
  id: string;
  stationId: string;
  /** Nullable — ERD §3.12: "may be preventive, not alert-driven". */
  alertId: string | null;
  interventionType: InterventionType;
  status: InterventionStatus;
  assignedTo: string;
  scheduledAt: Date;
  completedAt: Date | null;
}

/**
 * Separate aggregate from `Alert` (Domain Model §10: "MaintenanceIntervention
 * (separate aggregate, optionally referencing an Alert)"). `start()`/
 * `complete()`/`cancel()` have no HTTP entry point in openapi.yaml (only
 * `GET`/`POST /ops/maintenance-interventions` are documented, no status-update
 * route) — built for domain completeness/testability now, same treatment as
 * `Alert.raise()`; flagged as an OpenAPI gap, not silently assumed away.
 */
export class MaintenanceIntervention {
  private static readonly TRANSITIONS: Readonly<Record<InterventionStatus, readonly InterventionStatus[]>> = {
    scheduled: ['in_progress', 'cancelled'],
    in_progress: ['completed', 'cancelled'],
    completed: [],
    cancelled: [],
  };

  private constructor(private props: MaintenanceInterventionProps) {}

  static schedule(params: {
    id: string;
    stationId: string;
    alertId?: string | null;
    interventionType: InterventionType;
    assignedTo: string;
    scheduledAt: Date;
  }): MaintenanceIntervention {
    return new MaintenanceIntervention({
      id: params.id,
      stationId: params.stationId,
      alertId: params.alertId ?? null,
      interventionType: params.interventionType,
      status: 'scheduled',
      assignedTo: params.assignedTo,
      scheduledAt: params.scheduledAt,
      completedAt: null,
    });
  }

  static restore(props: MaintenanceInterventionProps): MaintenanceIntervention {
    return new MaintenanceIntervention(props);
  }

  start(): void {
    this.transitionTo('in_progress');
  }

  complete(): void {
    this.transitionTo('completed');
    this.props = { ...this.props, completedAt: new Date() };
  }

  cancel(): void {
    this.transitionTo('cancelled');
  }

  private transitionTo(next: InterventionStatus): void {
    const allowed = MaintenanceIntervention.TRANSITIONS[this.props.status];
    if (!allowed.includes(next)) {
      throw new InvalidInterventionStatusTransitionException(this.props.status, next);
    }
    this.props = { ...this.props, status: next };
  }

  get id(): string {
    return this.props.id;
  }

  get stationId(): string {
    return this.props.stationId;
  }

  get alertId(): string | null {
    return this.props.alertId;
  }

  get interventionType(): InterventionType {
    return this.props.interventionType;
  }

  get status(): InterventionStatus {
    return this.props.status;
  }

  get assignedTo(): string {
    return this.props.assignedTo;
  }

  get scheduledAt(): Date {
    return this.props.scheduledAt;
  }

  get completedAt(): Date | null {
    return this.props.completedAt;
  }
}
