import { Injectable } from '@nestjs/common';
import { AccessSession as PrismaAccessSession, Prisma, Transaction as PrismaTransaction } from '@prisma/client';
import { Money } from '../../../../shared-kernel';
import { PrismaService } from '../../../../platform/database/prisma.service';
import { AccessSession } from '../../domain/entities/access-session.entity';
import { AccessSessionRepository, VisitHistoryPage, VisitHistoryRow } from '../../domain/ports/access-session.repository';
import { assertAccessSessionStatus } from '../../domain/value-objects/access-session-status.vo';
import { decodeVisitHistoryCursor, encodeVisitHistoryCursor } from './visit-history-cursor';

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

  /**
   * GET /users/me/visit-history (EPIC-05 US-05.2) — only `completed` sessions
   * count as a visit (see the port doc comment), ordered most-recent-first
   * via `closedAt DESC, id DESC` with a keyset cursor on that same compound
   * key (api-architecture.md §6; encoding mirrors station-network's own
   * `search-cursor.ts` technique, duplicated locally per module-dependency-diagram.md
   * §5 rule 1 — see visit-history-cursor.ts).
   */
  async listVisitHistoryForUser(userId: string, cursor: string | null, limit: number): Promise<VisitHistoryPage> {
    const decodedCursor = cursor ? decodeVisitHistoryCursor(cursor) : null;
    const cursorClause: Prisma.AccessSessionWhereInput = decodedCursor
      ? {
          OR: [
            { closedAt: { lt: new Date(decodedCursor.closedAt) } },
            { closedAt: new Date(decodedCursor.closedAt), id: { lt: decodedCursor.id } },
          ],
        }
      : {};

    const records = await this.prisma.accessSession.findMany({
      where: { userId, status: 'completed', ...cursorClause },
      include: { transaction: true },
      orderBy: [{ closedAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
    });

    const hasMore = records.length > limit;
    const page = hasMore ? records.slice(0, limit) : records;
    const last = page[page.length - 1];

    return {
      data: page.map((record) => this.toVisitHistoryRow(record)),
      nextCursor:
        hasMore && last
          ? encodeVisitHistoryCursor({
              // Invariant: only `completed` sessions are queried, and complete()
              // (access-session.entity.ts) sets closedAt in the same transition —
              // so closedAt is always non-null here despite the nullable DB column.
              closedAt: last.closedAt!.toISOString(),
              id: last.id,
            })
          : null,
    };
  }

  private toVisitHistoryRow(record: PrismaAccessSession & { transaction: PrismaTransaction | null }): VisitHistoryRow {
    return {
      id: record.id,
      cabinId: record.cabinId,
      // Same non-null invariant as above.
      closedAt: record.closedAt!,
      amount: record.transaction
        ? Money.fromDecimalString(record.transaction.amount.toString(), record.transaction.currency)
        : null,
    };
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
