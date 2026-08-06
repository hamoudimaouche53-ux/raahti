import { Money } from '../../../../shared-kernel';
import { Transaction } from '../../domain/entities/transaction.entity';
import { PrismaTransactionRepository } from './prisma-transaction.repository';

function createPrismaMock() {
  return {
    transaction: { upsert: jest.fn(), findUnique: jest.fn() },
  } as any;
}

const RECORD = {
  id: 't1',
  userId: 'u1',
  accessSessionId: 'as1',
  paymentMethodId: 'pm1',
  amount: { toString: () => '50.00' },
  currency: 'DZD',
  discountApplied: null,
  status: 'captured',
  providerRef: 'prov-1',
  createdAt: new Date('2026-08-01T00:00:00Z'),
};

describe('PrismaTransactionRepository', () => {
  it('upserts on save and returns the same transaction', async () => {
    const prisma = createPrismaMock();
    const repo = new PrismaTransactionRepository(prisma);
    const transaction = Transaction.pending({
      id: 't1',
      userId: 'u1',
      accessSessionId: 'as1',
      amount: Money.fromDecimalString('50.00', 'DZD'),
    });

    const result = await repo.save(transaction);

    expect(result).toBe(transaction);
    expect(prisma.transaction.upsert).toHaveBeenCalledWith(expect.objectContaining({ where: { id: 't1' } }));
  });

  it('returns null when the transaction is not found', async () => {
    const prisma = createPrismaMock();
    prisma.transaction.findUnique.mockResolvedValue(null);
    const repo = new PrismaTransactionRepository(prisma);

    expect(await repo.findById('missing')).toBeNull();
  });

  it('maps a record into the domain entity', async () => {
    const prisma = createPrismaMock();
    prisma.transaction.findUnique.mockResolvedValue(RECORD);
    const repo = new PrismaTransactionRepository(prisma);

    const transaction = await repo.findById('t1');

    expect(transaction?.id).toBe('t1');
    expect(transaction?.status).toBe('captured');
    expect(transaction?.amount.toDecimalString()).toBe('50.00');
  });

  it('finds by accessSessionId', async () => {
    const prisma = createPrismaMock();
    prisma.transaction.findUnique.mockResolvedValue(RECORD);
    const repo = new PrismaTransactionRepository(prisma);

    const transaction = await repo.findByAccessSessionId('as1');

    expect(transaction?.id).toBe('t1');
    expect(prisma.transaction.findUnique).toHaveBeenCalledWith({ where: { accessSessionId: 'as1' } });
  });

  it('maps a non-null discountApplied', async () => {
    const prisma = createPrismaMock();
    prisma.transaction.findUnique.mockResolvedValue({ ...RECORD, discountApplied: { toString: () => '50.00' } });
    const repo = new PrismaTransactionRepository(prisma);

    const transaction = await repo.findById('t1');

    expect(transaction?.discountApplied).toBe(50);
  });
});
