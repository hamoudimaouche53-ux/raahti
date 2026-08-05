import { LanguagePreference } from '../../../shared-kernel';
import { User } from '../domain/entities/user.entity';
import { PrismaUserRepository } from './prisma-user.repository';

function createPrismaMock() {
  return {
    user: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
  } as any;
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
});
