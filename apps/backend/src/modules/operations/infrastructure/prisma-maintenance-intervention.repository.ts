import { Injectable } from '@nestjs/common';
import { MaintenanceIntervention as PrismaMaintenanceIntervention } from '@prisma/client';
import { PrismaService } from '../../../platform/database/prisma.service';
import { MaintenanceIntervention } from '../domain/entities/maintenance-intervention.entity';
import { MaintenanceInterventionRepository } from '../domain/ports/maintenance-intervention.repository';
import { assertInterventionStatus } from '../domain/value-objects/intervention-status.vo';
import { assertInterventionType } from '../domain/value-objects/intervention-type.vo';

@Injectable()
export class PrismaMaintenanceInterventionRepository implements MaintenanceInterventionRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(intervention: MaintenanceIntervention): Promise<void> {
    await this.prisma.maintenanceIntervention.upsert({
      where: { id: intervention.id },
      create: {
        id: intervention.id,
        stationId: intervention.stationId,
        alertId: intervention.alertId,
        interventionType: intervention.interventionType,
        status: intervention.status,
        assignedTo: intervention.assignedTo,
        scheduledAt: intervention.scheduledAt,
        completedAt: intervention.completedAt,
      },
      update: {
        status: intervention.status,
        completedAt: intervention.completedAt,
      },
    });
  }

  /** FR-OPS-03: no ordering specified by the contract — soonest-scheduled first is the natural operational default. */
  async findAll(): Promise<MaintenanceIntervention[]> {
    const records = await this.prisma.maintenanceIntervention.findMany({ orderBy: { scheduledAt: 'asc' } });
    return records.map((record) => this.toDomain(record));
  }

  private toDomain(record: PrismaMaintenanceIntervention): MaintenanceIntervention {
    assertInterventionType(record.interventionType);
    assertInterventionStatus(record.status);
    return MaintenanceIntervention.restore({
      id: record.id,
      stationId: record.stationId,
      alertId: record.alertId,
      interventionType: record.interventionType,
      status: record.status,
      assignedTo: record.assignedTo,
      scheduledAt: record.scheduledAt,
      completedAt: record.completedAt,
    });
  }
}
