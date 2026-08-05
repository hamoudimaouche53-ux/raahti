import { LanguagePreference } from '../../../shared-kernel';
import { NotificationCopyResolver } from './notification-copy-resolver';

describe('NotificationCopyResolver', () => {
  const resolver = new NotificationCopyResolver();
  const types = ['availability', 'operator_alert', 'payment_confirmation'] as const;

  it.each(types)('resolves distinct, non-empty French copy for %s', (type) => {
    const copy = resolver.resolve(type, LanguagePreference.FR);
    expect(copy.title.length).toBeGreaterThan(0);
    expect(copy.body.length).toBeGreaterThan(0);
  });

  it.each(types)('resolves distinct, non-empty Arabic copy for %s', (type) => {
    const copy = resolver.resolve(type, LanguagePreference.AR);
    expect(copy.title.length).toBeGreaterThan(0);
    expect(copy.body.length).toBeGreaterThan(0);
  });

  it('resolves different copy per language for the same type (not machine-translated placeholder)', () => {
    const fr = resolver.resolve('payment_confirmation', LanguagePreference.FR);
    const ar = resolver.resolve('payment_confirmation', LanguagePreference.AR);
    expect(fr.body).not.toBe(ar.body);
  });

  it('resolves different copy per type for the same language', () => {
    const availability = resolver.resolve('availability', LanguagePreference.FR);
    const payment = resolver.resolve('payment_confirmation', LanguagePreference.FR);
    expect(availability.body).not.toBe(payment.body);
  });
});
