import { Injectable } from '@nestjs/common';
import { AccessSession as PrismaAccessSession } from '@prisma/client';
import { PrismaService } from '../../../../platform/database/prisma.service';
import { AccessSession } from '../../domain/entities/access-session.entity';
import { AccessSessionRepository } from '../../domain/ports/access-session.repository';
import { assertAccessSessionStatus } from '../../domain/value-objects/access-session-status.vo';

@Injectable()
export class PrismaAccessSessionRepository implements AccessSessionRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(session: AccessSession): Promise<AccessSession> {
    await this.prisma.accessSession.upsert({
      where: { id: session.id },
      create: {
        id: session.id,
        cabinId: session.cabinId,
        userId: session.userId,
        status: session.status,
        qrCodeScanned: session.qrCodeScanned,
        startedAt: session.startedAt,
        unlockedAt: session.unlockedAt,
        closedAt: session.closedAt,
      },
      update: {
        status: session.status,
        unlockedAt: session.unlockedAt,
        closedAt: session.closedAt,
      },
    });
    return session;
  }

  async findById(id: string): Promise<AccessSession | null> {
    const record = await this.prisma.accessSession.findUnique({ where: { id } });
    return record ? this.toDomain(record) : null;
  }

  /** ERD §3.10 "idx_access_session_cabin_status" — most recent non-terminal session for the cabin. */
  async findActiveByCabinId(cabinId: string): Promise<AccessSession | null> {
    const record = await this.prisma.accessSession.findFirst({
      where: { cabinId, status: { notIn: ['completed', 'cancelled'] } },
      orderBy: { startedAt: 'desc' },
    });
    return record ? this.toDomain(record) : null;
  }

  private toDomain(record: PrismaAccessSession): AccessSession {
    assertAccessSessionStatus(record.status);
    return AccessSession.restore({
      id: record.id,
      cabinId: record.cabinId,
      userId: record.userId,
      status: record.status,
      qrCodeScanned: record.qrCodeScanned,
      startedAt: record.startedAt,
      unlockedAt: record.unlockedAt,
      closedAt: record.closedAt,
    });
  }
}
