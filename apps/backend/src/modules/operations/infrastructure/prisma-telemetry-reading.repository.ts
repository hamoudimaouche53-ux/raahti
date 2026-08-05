import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../platform/database/prisma.service';
import { TelemetryMetric, TelemetryReadingRepository, TelemetrySeriesPoint } from '../domain/ports/telemetry-reading.repository';

@Injectable()
export class PrismaTelemetryReadingRepository implements TelemetryReadingRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findLatestValue(stationId: string, metric: TelemetryMetric): Promise<number | null> {
    const record = await this.prisma.telemetryReading.findFirst({
      where: { stationId, metric, cabinId: null },
      orderBy: { recordedAt: 'desc' },
    });
    return record ? Number(record.value) : null;
  }

  async findSeries(stationId: string, metric: TelemetryMetric, from: Date, to: Date): Promise<TelemetrySeriesPoint[]> {
    const records = await this.prisma.telemetryReading.findMany({
      where: { stationId, metric, recordedAt: { gte: from, lte: to } },
      orderBy: { recordedAt: 'asc' },
    });
    return records.map((record) => ({ recordedAt: record.recordedAt, value: Number(record.value) }));
  }
}
