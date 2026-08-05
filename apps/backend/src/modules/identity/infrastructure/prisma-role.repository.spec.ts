import { PrismaRoleRepository } from './prisma-role.repository';

function createPrismaMock() {
  return {
    role: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
    },
  } as any;
}

describe('PrismaRoleRepository', () => {
  it('maps a found role record to a domain Role', async () => {
    const prisma = createPrismaMock();
    prisma.role.findUnique.mockResolvedValue({ id: 'r1', code: 'admin', labelFr: 'Administrateur', labelAr: 'مدير' });
    const repo = new PrismaRoleRepository(prisma);

    const role = await repo.findByCode('admin');

    expect(role).toEqual(expect.objectContaining({ id: 'r1', code: 'admin', labelFr: 'Administrateur' }));
  });

  it('returns null when the role code is not found', async () => {
    const prisma = createPrismaMock();
    prisma.role.findUnique.mockResolvedValue(null);
    const repo = new PrismaRoleRepository(prisma);

    expect(await repo.findByCode('admin')).toBeNull();
  });

  it('lists all roles', async () => {
    const prisma = createPrismaMock();
    prisma.role.findMany.mockResolvedValue([
      { id: 'r1', code: 'usager', labelFr: 'Usager', labelAr: 'مستخدم' },
      { id: 'r2', code: 'admin', labelFr: 'Administrateur', labelAr: 'مدير' },
    ]);
    const repo = new PrismaRoleRepository(prisma);

    const roles = await repo.list();

    expect(roles).toHaveLength(2);
    expect(roles.map((r) => r.code)).toEqual(['usager', 'admin']);
  });
});
