import { AccessSession } from '../../domain/entities/access-session.entity';
import { PrismaAccessSessionRepository } from './prisma-access-session.repository';

function createPrismaMock() {
  return {
    accessSession: { upsert: jest.fn(), findUnique: jest.fn(), findFirst: jest.fn() },
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
});
