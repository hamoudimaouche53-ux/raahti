import { Injectable } from '@nestjs/common';
import { PaymentMethod as PrismaPaymentMethod } from '@prisma/client';
import { PrismaService } from '../../../platform/database/prisma.service';
import { PaymentMethod } from '../domain/entities/payment-method.entity';
import { PaymentMethodRepository } from '../domain/ports/payment-method.repository';
import { assertPaymentMethodType } from '../domain/value-objects/payment-method-type.vo';

@Injectable()
export class PrismaPaymentMethodRepository implements PaymentMethodRepository {
  constructor(private readonly prisma: PrismaService) {}

  async save(method: PaymentMethod): Promise<void> {
    await this.prisma.paymentMethod.create({
      data: {
        id: method.id,
        userId: method.userId,
        methodType: method.methodType,
        providerRef: method.providerRef,
        isDefault: method.isDefault,
      },
    });
  }

  async listByUserId(userId: string): Promise<PaymentMethod[]> {
    const records = await this.prisma.paymentMethod.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });
    return records.map((record) => this.toDomain(record));
  }

  private toDomain(record: PrismaPaymentMethod): PaymentMethod {
    assertPaymentMethodType(record.methodType);
    return PaymentMethod.restore({
      id: record.id,
      userId: record.userId,
      methodType: record.methodType,
      providerRef: record.providerRef,
      isDefault: record.isDefault,
      createdAt: record.createdAt,
    });
  }
}
