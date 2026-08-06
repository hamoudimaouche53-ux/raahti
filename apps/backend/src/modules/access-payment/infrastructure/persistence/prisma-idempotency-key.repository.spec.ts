import { PrismaIdempotencyKeyRepository } from './prisma-idempotency-key.repository';

function createPrismaMock() {
  return {
    idempotencyKey: { findUnique: jest.fn(), upsert: jest.fn() },
  } as any;
}

describe('PrismaIdempotencyKeyRepository', () => {
  it('returns null when no record exists', async () => {
    const prisma = createPrismaMock();
    prisma.idempotencyKey.findUnique.mockResolvedValue(null);
    const repo = new PrismaIdempotencyKeyRepository(prisma);

    expect(await repo.find('u1', 'k1', 'E')).toBeNull();
  });

  it('returns null when the record exists but has no responseStatus yet', async () => {
    const prisma = createPrismaMock();
    prisma.idempotencyKey.findUnique.mockResolvedValue({ responseStatus: null, responseBody: null });
    const repo = new PrismaIdempotencyKeyRepository(prisma);

    expect(await repo.find('u1', 'k1', 'E')).toBeNull();
  });

  it('returns the cached response when present', async () => {
    const prisma = createPrismaMock();
    prisma.idempotencyKey.findUnique.mockResolvedValue({ responseStatus: 201, responseBody: { id: 'as1' } });
    const repo = new PrismaIdempotencyKeyRepository(prisma);

    expect(await repo.find('u1', 'k1', 'E')).toEqual({ responseStatus: 201, responseBody: { id: 'as1' } });
    expect(prisma.idempotencyKey.findUnique).toHaveBeenCalledWith({
      where: { userId_key_endpoint: { userId: 'u1', key: 'k1', endpoint: 'E' } },
    });
  });

  it('upserts on save', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaIdempotencyKeyRepository(prisma);

    await repo.save('u1', 'k1', 'E', 201, { id: 'as1' });

    expect(prisma.idempotencyKey.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId_key_endpoint: { userId: 'u1', key: 'k1', endpoint: 'E' } },
        update: { responseStatus: 201, responseBody: { id: 'as1' } },
      }),
    );
  });
});
