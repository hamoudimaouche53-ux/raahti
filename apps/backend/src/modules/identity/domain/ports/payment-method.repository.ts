import { PaymentMethod } from '../entities/payment-method.entity';

export const PAYMENT_METHOD_REPOSITORY = Symbol('PAYMENT_METHOD_REPOSITORY');

export interface PaymentMethodRepository {
  save(method: PaymentMethod): Promise<void>;
  listByUserId(userId: string): Promise<PaymentMethod[]>;
}
