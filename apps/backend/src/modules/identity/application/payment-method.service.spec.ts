import { PaymentMethodRepository } from '../domain/ports/payment-method.repository';
import { InvalidPaymentMethodTypeException } from '../domain/value-objects/payment-method-type.vo';
import { PaymentMethodService } from './payment-method.service';

describe('PaymentMethodService', () => {
  it('creates a payment method from a provider token, never storing raw card data', async () => {
    const repo: jest.Mocked<PaymentMethodRepository> = { save: jest.fn(), listByUserId: jest.fn() };
    const service = new PaymentMethodService(repo);

    const method = await service.create('u1', { methodType: 'card', providerToken: 'tok_abc123' });

    expect(method.providerRef).toBe('tok_abc123');
    expect(method.methodType).toBe('card');
    expect(repo.save).toHaveBeenCalledWith(method);
  });

  it('rejects an unrecognized method type', async () => {
    const repo: jest.Mocked<PaymentMethodRepository> = { save: jest.fn(), listByUserId: jest.fn() };
    const service = new PaymentMethodService(repo);

    await expect(service.create('u1', { methodType: 'crypto', providerToken: 'tok' })).rejects.toThrow(
      InvalidPaymentMethodTypeException,
    );
  });

  it('lists a user\'s payment methods', async () => {
    const repo: jest.Mocked<PaymentMethodRepository> = { save: jest.fn(), listByUserId: jest.fn().mockResolvedValue([]) };
    const service = new PaymentMethodService(repo);

    await service.list('u1');

    expect(repo.listByUserId).toHaveBeenCalledWith('u1');
  });
});
