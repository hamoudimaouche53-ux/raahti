import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { MaintenanceIntervention } from '../domain/entities/maintenance-intervention.entity';
import {
  MAINTENANCE_INTERVENTION_REPOSITORY,
  MaintenanceInterventionRepository,
} from '../domain/ports/maintenance-intervention.repository';
import { InterventionType } from '../domain/value-objects/intervention-type.vo';

export interface ScheduleInterventionParams {
  stationId: string;
  alertId?: string | null;
  interventionType: InterventionType;
  scheduledAt: Date;
  /** Optional in openapi.yaml's MaintenanceInterventionCreateRequest — see schedule()'s doc comment. */
  assignedTo?: string;
}

@Injectable()
export class MaintenanceInterventionService {
  constructor(
    @Inject(MAINTENANCE_INTERVENTION_REPOSITORY)
    private readonly maintenanceInterventionRepository: MaintenanceInterventionRepository,
  ) {}

  /** GET /ops/maintenance-interventions (FR-OPS-03). */
  async list(): Promise<MaintenanceIntervention[]> {
    return this.maintenanceInterventionRepository.findAll();
  }

  /**
   * POST /ops/maintenance-interventions (FR-OPS-03). `assignedTo` is optional
   * in `MaintenanceInterventionCreateRequest` (openapi.yaml — not in its
   * `required` list) but NOT NULL in the ERD (§3.12: "assigned_to FK,
   * references USER_ACCOUNT (operateur)"). Reconciled by defaulting to the
   * scheduling operator when omitted, rather than relaxing the domain/DB
   * invariant or inventing a new optional-assignee concept not in the ERD —
   * flagged judgment call, not a silent assumption.
   */
  async schedule(params: ScheduleInterventionParams, schedulingOperatorId: string): Promise<MaintenanceIntervention> {
    const intervention = MaintenanceIntervention.schedule({
      id: randomUUID(),
      stationId: params.stationId,
      alertId: params.alertId ?? null,
      interventionType: params.interventionType,
      assignedTo: params.assignedTo ?? schedulingOperatorId,
      scheduledAt: params.scheduledAt,
    });
    await this.maintenanceInterventionRepository.save(intervention);
    return intervention;
  }
}
