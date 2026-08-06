import { Injectable } from '@nestjs/common';
import { Transaction as PrismaTransaction } from '@prisma/client';
import { Money } from '../../../../shared-kernel';
import { PrismaService } from '../../../../platform/database/prisma.service';
import { Transaction } from '../../domain/entities/transaction.entity';
import { TransactionRepository } from '../../domain/ports/transaction.repository';
import { assertTransactionStatus } from '../../domain/value-objects/transaction-status.vo';

@Injectable()
export class PrismaTransactionRepository implements TransactionRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(transaction: Transaction): Promise<Transaction> {
    await this.prisma.transaction.upsert({
      where: { id: transaction.id },
      create: {
        id: transaction.id,
        userId: transaction.userId,
        accessSessionId: transaction.accessSessionId,
        paymentMethodId: transaction.paymentMethodId,
        amount: transaction.amount.toDecimalString(),
        currency: transaction.amount.currency,
        discountApplied: transaction.discountApplied,
        status: transaction.status,
        providerRef: transaction.providerRef,
        createdAt: transaction.createdAt,
      },
      update: {
        status: transaction.status,
        providerRef: transaction.providerRef,
      },
    });
    return transaction;
  }

  async findById(id: string): Promise<Transaction | null> {
    const record = await this.prisma.transaction.findUnique({ where: { id } });
    return record ? this.toDomain(record) : null;
  }

  async findByAccessSessionId(accessSessionId: string): Promise<Transaction | null> {
    const record = await this.prisma.transaction.findUnique({ where: { accessSessionId } });
    return record ? this.toDomain(record) : null;
  }

  private toDomain(record: PrismaTransaction): Transaction {
    assertTransactionStatus(record.status);
    return Transaction.restore({
      id: record.id,
      userId: record.userId,
      accessSessionId: record.accessSessionId,
      paymentMethodId: record.paymentMethodId,
      amount: Money.fromDecimalString(record.amount.toString(), record.currency),
      discountApplied: record.discountApplied ? Number(record.discountApplied.toString()) : null,
      status: record.status,
      providerRef: record.providerRef,
      createdAt: record.createdAt,
    });
  }
}
