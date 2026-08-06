import { AccessSession } from '../../domain/entities/access-session.entity';
import { PrismaAccessSessionRepository } from './prisma-access-session.repository';
import { decodeVisitHistoryCursor, encodeVisitHistoryCursor } from './visit-history-cursor';

function createPrismaMock() {
  return {
    accessSession: { upsert: jest.fn(), findUnique: jest.fn(), findFirst: jest.fn(), findMany: jest.fn() },
  } as any;
}

const RECORD = {
  id: 'as1',
  cabinId: 'c1',
  userId: 'u1',
  status: 'initiated',
  qrCodeScanned: 'c1',
  startedAt: new Date('2026-08-01T00:00:00Z'),
  unlockedAt: null,
  closedAt: null,
};

describe('PrismaAccessSessionRepository', () => {
  it('upserts on save and returns the same session', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaAccessSessionRepository(prisma);
    const session = AccessSession.initiate({ id: 'as1', cabinId: 'c1', userId: 'u1', qrCodeScanned: 'c1' });

    const result = await repo.save(session);

    expect(result).toBe(session);
    expect(prisma.accessSession.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'as1' } }),
    );
  });

  it('returns null when the session is not found', async () => {
    const prisma = createPrismaMock();
    prisma.accessSession.findUnique.mockResolvedValue(null);
    const repo = new PrismaAccessSessionRepository(prisma);

    expect(await repo.findById('missing')).toBeNull();
  });

  it('maps a record into the domain entity', async () => {
    const prisma = createPrismaMock();
    prisma.accessSession.findUnique.mockResolvedValue(RECORD);
    const repo = new PrismaAccessSessionRepository(prisma);

    const session = await repo.findById('as1');

    expect(session?.id).toBe('as1');
    expect(session?.status).toBe('initiated');
  });

  it('finds the active session for a cabin, excluding completed/cancelled', async () => {
    const prisma = createPrismaMock();
    prisma.accessSession.findFirst.mockResolvedValue(RECORD);
    const repo = new PrismaAccessSessionRepository(prisma);

    const session = await repo.findActiveByCabinId('c1');

    expect(session?.id).toBe('as1');
    expect(prisma.accessSession.findFirst).toHaveBeenCalledWith({
      where: { cabinId: 'c1', status: { notIn: ['completed', 'cancelled'] } },
      orderBy: { startedAt: 'desc' },
    });
  });

  describe('listVisitHistoryForUser', () => {
    const CLOSED_AT_1 = new Date('2026-08-01T10:00:00Z');
    const CLOSED_AT_2 = new Date('2026-07-15T09:00:00Z');

    function completedRecord(
      overrides: Partial<Omit<typeof RECORD, 'closedAt'>> & { closedAt?: Date; transaction?: unknown } = {},
    ) {
      return {
        ...RECORD,
        status: 'completed',
        closedAt: CLOSED_AT_1,
        transaction: null,
        ...overrides,
      };
    }

    it('queries only completed sessions for the user, ordered closedAt desc / id desc', async () => {
      const prisma = createPrismaMock();
      prisma.accessSession.findMany.mockResolvedValue([]);
      const repo = new PrismaAccessSessionRepository(prisma);

      await repo.listVisitHistoryForUser('u1', null, 20);

      expect(prisma.accessSession.findMany).toHaveBeenCalledWith({
        where: { userId: 'u1', status: 'completed' },
        include: { transaction: true },
        orderBy: [{ closedAt: 'desc' }, { id: 'desc' }],
        take: 21,
      });
    });

    it('maps a transaction-present row to a non-null Money amount', async () => {
      const prisma = createPrismaMock();
      prisma.accessSession.findMany.mockResolvedValue([
        completedRecord({
          id: 'as1',
          cabinId: 'c1',
          transaction: { amount: { toString: () => '50.00' }, currency: 'DZD' },
        }),
      ]);
      const repo = new PrismaAccessSessionRepository(prisma);

      const page = await repo.listVisitHistoryForUser('u1', null, 20);

      expect(page.data).toHaveLength(1);
      expect(page.data[0].id).toBe('as1');
      expect(page.data[0].cabinId).toBe('c1');
      expect(page.data[0].closedAt).toEqual(CLOSED_AT_1);
      expect(page.data[0].amount?.toDecimalString()).toBe('50.00');
    });

    it('maps a transaction-absent row (free cabin) to a null amount', async () => {
      const prisma = createPrismaMock();
      prisma.accessSession.findMany.mockResolvedValue([completedRecord({ id: 'as2', transaction: null })]);
      const repo = new PrismaAccessSessionRepository(prisma);

      const page = await repo.listVisitHistoryForUser('u1', null, 20);

      expect(page.data[0].amount).toBeNull();
    });

    it('returns nextCursor null when there is no next page', async () => {
      const prisma = createPrismaMock();
      prisma.accessSession.findMany.mockResolvedValue([completedRecord({ id: 'as1' })]);
      const repo = new PrismaAccessSessionRepository(prisma);

      const page = await repo.listVisitHistoryForUser('u1', null, 20);

      expect(page.nextCursor).toBeNull();
    });

    it('returns an encoded nextCursor (closedAt, id) of the last returned row when more results exist', async () => {
      const prisma = createPrismaMock();
      const extra = completedRecord({ id: 'as-extra', closedAt: CLOSED_AT_2 });
      prisma.accessSession.findMany.mockResolvedValue([completedRecord({ id: 'as1' }), extra]);
      const repo = new PrismaAccessSessionRepository(prisma);

      const page = await repo.listVisitHistoryForUser('u1', null, 1);

      expect(page.data).toHaveLength(1);
      expect(page.nextCursor).not.toBeNull();
      expect(decodeVisitHistoryCursor(page.nextCursor!)).toEqual({
        closedAt: CLOSED_AT_1.toISOString(),
        id: 'as1',
      });
    });

    it('decodes an incoming cursor into a (closedAt, id) keyset WHERE clause', async () => {
      const prisma = createPrismaMock();
      prisma.accessSession.findMany.mockResolvedValue([]);
      const repo = new PrismaAccessSessionRepository(prisma);
      const cursor = encodeVisitHistoryCursor({ closedAt: CLOSED_AT_1.toISOString(), id: 'as1' });

      await repo.listVisitHistoryForUser('u1', cursor, 20);

      expect(prisma.accessSession.findMany).toHaveBeenCalledWith({
        where: {
          userId: 'u1',
          status: 'completed',
          OR: [{ closedAt: { lt: CLOSED_AT_1 } }, { closedAt: CLOSED_AT_1, id: { lt: 'as1' } }],
        },
        include: { transaction: true },
        orderBy: [{ closedAt: 'desc' }, { id: 'desc' }],
        take: 21,
      });
    });
  });
});
