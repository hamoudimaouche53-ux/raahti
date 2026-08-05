import { LanguagePreference } from '../../../../shared-kernel';
import { MissingContactMethodException, User } from './user.entity';

describe('User', () => {
  it('creates with only an email', () => {
    const user = User.create({ id: 'u1', email: 'a@example.com' });
    expect(user.email).toBe('a@example.com');
    expect(user.phone).toBeNull();
  });

  it('creates with only a phone', () => {
    const user = User.create({ id: 'u1', phone: '+213555000000' });
    expect(user.phone).toBe('+213555000000');
  });

  it('rejects creation with neither email nor phone (FR-USR-01 account invariant)', () => {
    expect(() => User.create({ id: 'u1' })).toThrow(MissingContactMethodException);
    expect(() => User.create({ id: 'u1', email: null, phone: null })).toThrow(MissingContactMethodException);
  });

  it('defaults preferredLanguage to fr and diabeticVerificationStatus to none', () => {
    const user = User.create({ id: 'u1', email: 'a@example.com' });
    expect(user.preferredLanguage.equals(LanguagePreference.FR)).toBe(true);
    expect(user.diabeticVerificationStatus).toBe('none');
  });

  it('defaults isActive to true', () => {
    const user = User.create({ id: 'u1', email: 'a@example.com' });
    expect(user.isActive).toBe(true);
  });
});
