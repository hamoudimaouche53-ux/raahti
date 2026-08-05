import { PaymentMethod } from '../domain/entities/payment-method.entity';
import { PrismaPaymentMethodRepository } from './prisma-payment-method.repository';

function createPrismaMock() {
  return { paymentMethod: { create: jest.fn(), findMany: jest.fn() } } as any;
}

describe('PrismaPaymentMethodRepository', () => {
  it('creates a payment method row from the domain entity', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaPaymentMethodRepository(prisma);
    const method = PaymentMethod.create({ id: 'm1', userId: 'u1', methodType: 'card', providerRef: 'tok_1' });

    await repo.save(method);

    expect(prisma.paymentMethod.create).toHaveBeenCalledWith({
      data: { id: 'm1', userId: 'u1', methodType: 'card', providerRef: 'tok_1', isDefault: false },
    });
  });

  it('lists and maps payment methods for a user', async () => {
    const prisma = createPrismaMock();
    prisma.paymentMethod.findMany.mockResolvedValue([
      {
        id: 'm1',
        userId: 'u1',
        methodType: 'mobile_wallet',
        providerRef: 'tok_1',
        isDefault: true,
        createdAt: new Date(),
      },
    ]);
    const repo = new PrismaPaymentMethodRepository(prisma);

    const methods = await repo.listByUserId('u1');

    expect(methods).toHaveLength(1);
    expect(methods[0].methodType).toBe('mobile_wallet');
    expect(prisma.paymentMethod.findMany).toHaveBeenCalledWith({ where: { userId: 'u1' }, orderBy: { createdAt: 'asc' } });
  });
});
