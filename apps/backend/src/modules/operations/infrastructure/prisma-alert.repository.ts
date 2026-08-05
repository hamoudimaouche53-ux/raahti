import { Injectable } from '@nestjs/common';
import { Alert as PrismaAlert } from '@prisma/client';
import { PrismaService } from '../../../platform/database/prisma.service';
import { Alert } from '../domain/entities/alert.entity';
import { AlertRepository } from '../domain/ports/alert.repository';
import { ALERT_SEVERITY_RANK, assertAlertSeverity } from '../domain/value-objects/alert-severity.vo';
import { assertAlertStatus, AlertStatus } from '../domain/value-objects/alert-status.vo';
import { assertAlertType } from '../domain/value-objects/alert-type.vo';

@Injectable()
export class PrismaAlertRepository implements AlertRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(alert: Alert): Promise<void> {
    await this.prisma.alert.upsert({
      where: { id: alert.id },
      create: {
        id: alert.id,
        stationId: alert.stationId,
        type: alert.type,
        severity: alert.severity,
        status: alert.status,
        acknowledgedBy: alert.acknowledgedBy,
        raisedAt: alert.raisedAt,
        resolvedAt: alert.resolvedAt,
      },
      update: {
        status: alert.status,
        acknowledgedBy: alert.acknowledgedBy,
        resolvedAt: alert.resolvedAt,
      },
    });
  }

  async findById(id: string): Promise<Alert | null> {
    const record = await this.prisma.alert.findUnique({ where: { id } });
    return record ? this.toDomain(record) : null;
  }

  /**
   * FR-OPS-02: severity DESC, then raisedAt ASC (openapi.yaml note on
   * `GET /ops/alerts`). Sorted in application code via `ALERT_SEVERITY_RANK`
   * rather than a DB `ORDER BY severity` — Postgres enum comparison order
   * follows declaration order, which would silently invert if the enum's
   * declaration order in schema.prisma ever changed; ranking explicitly
   * against the domain VO's map is the single source of truth instead.
   */
  async findAll(status?: AlertStatus): Promise<Alert[]> {
    const records = await this.prisma.alert.findMany({ where: status ? { status } : undefined });
    return records
      .map((record) => this.toDomain(record))
      .sort((a, b) => {
        const severityDelta = ALERT_SEVERITY_RANK[b.severity] - ALERT_SEVERITY_RANK[a.severity];
        return severityDelta !== 0 ? severityDelta : a.raisedAt.getTime() - b.raisedAt.getTime();
      });
  }

  async countActiveGroupedByStation(): Promise<Map<string, number>> {
    const groups = await this.prisma.alert.groupBy({
      by: ['stationId'],
      where: { status: { not: 'resolved' } },
      _count: { _all: true },
    });
    return new Map(groups.map((group) => [group.stationId, group._count._all]));
  }

  private toDomain(record: PrismaAlert): Alert {
    assertAlertType(record.type);
    assertAlertSeverity(record.severity);
    assertAlertStatus(record.status);
    return Alert.restore({
      id: record.id,
      stationId: record.stationId,
      type: record.type,
      severity: record.severity,
      status: record.status,
      acknowledgedBy: record.acknowledgedBy,
      raisedAt: record.raisedAt,
      resolvedAt: record.resolvedAt,
    });
  }
}
