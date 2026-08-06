import { Money } from '../../../../shared-kernel';
import { MockPaymentGatewayAdapter } from './mock-payment-gateway.adapter';

describe('MockPaymentGatewayAdapter', () => {
  it('authorizes and captures deterministically by default', async () => {
    const gateway = new MockPaymentGatewayAdapter();
    const amount = Money.fromDecimalString('50.00', 'DZD');

    const auth = await gateway.authorize(amount, 'pm1', 'idem-1');
    expect(auth.authorizationId).toBeTruthy();

    const capture = await gateway.capture(auth.authorizationId);
    expect(capture.captureId).toBeTruthy();

    const refund = await gateway.refund(capture.captureId, amount);
    expect(refund.refundId).toBeTruthy();

    const tokenized = await gateway.tokenizePaymentMethod('raw-token');
    expect(tokenized.providerRef).toBeTruthy();
  });

  it('declines authorize when configured with alwaysDecline', async () => {
    const gateway = new MockPaymentGatewayAdapter({ alwaysDecline: true });
    await expect(gateway.authorize(Money.fromDecimalString('50.00', 'DZD'), 'pm1', 'idem-1')).rejects.toThrow();
  });

  it('declines capture when configured with alwaysDecline', async () => {
    const gateway = new MockPaymentGatewayAdapter({ alwaysDecline: true });
    await expect(gateway.capture('auth1')).rejects.toThrow();
  });
});
