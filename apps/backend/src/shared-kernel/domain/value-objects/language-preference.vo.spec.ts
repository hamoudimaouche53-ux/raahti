import { InvalidLanguagePreferenceException, LanguagePreference } from './language-preference.vo';

describe('LanguagePreference', () => {
  it('accepts fr and ar', () => {
    expect(LanguagePreference.of('fr').code).toBe('fr');
    expect(LanguagePreference.of('ar').code).toBe('ar');
  });

  it('rejects en (bilingual scope, not trilingual — see Phase 4 Implementation Plan §5)', () => {
    expect(() => LanguagePreference.of('en')).toThrow(InvalidLanguagePreferenceException);
  });

  it('rejects arbitrary strings', () => {
    expect(() => LanguagePreference.of('xx')).toThrow(InvalidLanguagePreferenceException);
  });

  it('equals compares by code', () => {
    expect(LanguagePreference.of('fr').equals(LanguagePreference.FR)).toBe(true);
    expect(LanguagePreference.of('fr').equals(LanguagePreference.AR)).toBe(false);
  });
});
