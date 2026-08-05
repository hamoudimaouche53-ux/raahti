import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PaymentMethod } from '../domain/entities/payment-method.entity';
import { PAYMENT_METHOD_REPOSITORY, PaymentMethodRepository } from '../domain/ports/payment-method.repository';
import { assertPaymentMethodType, PaymentMethodType } from '../domain/value-objects/payment-method-type.vo';

@Injectable()
export class PaymentMethodService {
  constructor(
    @Inject(PAYMENT_METHOD_REPOSITORY) private readonly paymentMethodRepository: PaymentMethodRepository,
  ) {}

  /** GET /users/me/payment-methods. */
  async list(userId: string): Promise<PaymentMethod[]> {
    return this.paymentMethodRepository.listByUserId(userId);
  }

  /** POST /users/me/payment-methods. `providerToken` (request) becomes `providerRef` (stored/returned) — same opaque value, boundary-naming only (never raw card data, ADR-0014/NFR-SEC-03). */
  async create(userId: string, params: { methodType: string; providerToken: string }): Promise<PaymentMethod> {
    assertPaymentMethodType(params.methodType);
    const method = PaymentMethod.create({
      id: randomUUID(),
      userId,
      methodType: params.methodType as PaymentMethodType,
      providerRef: params.providerToken,
    });
    await this.paymentMethodRepository.save(method);
    return method;
  }
}
