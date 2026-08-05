import { Prisma } from '@prisma/client';
import { LanguagePreference } from '../../../shared-kernel';
import { ConflictingContactMethodException, User } from '../domain/entities/user.entity';
import { PrismaUserRepository } from './prisma-user.repository';

function createPrismaMock() {
  return {
    user: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
  } as any;
}

function createRecord(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'u1',
    email: 'a@example.com',
    phone: null,
    preferredLanguage: 'fr',
    diabeticVerificationStatus: 'none',
    isActive: true,
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
  };
}

describe('PrismaUserRepository', () => {
  it('maps a found Prisma record to a domain User', async () => {
    const prisma = createPrismaMock();
    prisma.user.findUnique.mockResolvedValue({
      id: 'u1',
      email: 'a@example.com',
      phone: null,
      preferredLanguage: 'ar',
      diabeticVerificationStatus: 'verified',
      isActive: true,
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-02'),
    });
    const repo = new PrismaUserRepository(prisma);

    const user = await repo.findById('u1');

    expect(user).not.toBeNull();
    expect(user!.email).toBe('a@example.com');
    expect(user!.preferredLanguage.equals(LanguagePreference.AR)).toBe(true);
    expect(user!.diabeticVerificationStatus).toBe('verified');
  });

  it('returns null when no record is found', async () => {
    const prisma = createPrismaMock();
    prisma.user.findUnique.mockResolvedValue(null);
    const repo = new PrismaUserRepository(prisma);

    expect(await repo.findByEmail('missing@example.com')).toBeNull();
  });

  it('upserts a domain User, translating VOs back to primitive columns', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaUserRepository(prisma);
    const user = User.create({ id: 'u1', email: 'a@example.com', preferredLanguage: LanguagePreference.AR });

    await repo.save(user);

    expect(prisma.user.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'u1' },
        create: expect.objectContaining({ id: 'u1', email: 'a@example.com', preferredLanguage: 'ar' }),
        update: expect.objectContaining({ email: 'a@example.com', preferredLanguage: 'ar' }),
      }),
    );
  });

  describe('findOrCreate (ADR-0028 JIT provisioning)', () => {
    it('issues a no-op update clause, never overwriting an existing row', async () => {
      const prisma = createPrismaMock();
      prisma.user.upsert.mockResolvedValue(createRecord({ preferredLanguage: 'ar' }));
      const repo = new PrismaUserRepository(prisma);
      const candidate = User.create({ id: 'u1', email: 'a@example.com' });

      const result = await repo.findOrCreate(candidate);

      expect(prisma.user.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ where: { id: 'u1' }, update: {} }),
      );
      // Proves the existing row's language survives a repeat JIT-provisioning call,
      // even though `candidate` (freshly constructed) defaults to fr.
      expect(result.preferredLanguage.equals(LanguagePreference.AR)).toBe(true);
    });

    it('translates a unique-constraint violation into ConflictingContactMethodException', async () => {
      const prisma = createPrismaMock();
      prisma.user.upsert.mockRejectedValue(
        new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
          code: 'P2002',
          clientVersion: 'test',
        }),
      );
      const repo = new PrismaUserRepository(prisma);
      const candidate = User.create({ id: 'u2', email: 'a@example.com' });

      await expect(repo.findOrCreate(candidate)).rejects.toThrow(ConflictingContactMethodException);
    });

    it('rethrows unrelated errors unchanged', async () => {
      const prisma = createPrismaMock();
      prisma.user.upsert.mockRejectedValue(new Error('connection lost'));
      const repo = new PrismaUserRepository(prisma);
      const candidate = User.create({ id: 'u2', email: 'a@example.com' });

      await expect(repo.findOrCreate(candidate)).rejects.toThrow('connection lost');
    });
  });
});
