import { MaintenanceIntervention } from '../entities/maintenance-intervention.entity';

export const MAINTENANCE_INTERVENTION_REPOSITORY = Symbol('MAINTENANCE_INTERVENTION_REPOSITORY');

export interface MaintenanceInterventionRepository {
  save(intervention: MaintenanceIntervention): Promise<void>;
  /** GET /ops/maintenance-interventions (FR-OPS-03) — no filters/pagination in the contract. */
  findAll(): Promise<MaintenanceIntervention[]>;
}
