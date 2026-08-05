import { DomainException } from '../domain-exception';

export type LanguagePreferenceCode = 'fr' | 'ar';

const VALID_CODES: readonly LanguagePreferenceCode[] = ['fr', 'ar'];

export class InvalidLanguagePreferenceException extends DomainException {
  readonly code = 'SHARED_KERNEL_INVALID_LANGUAGE_PREFERENCE';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a supported language preference (expected fr|ar).`);
  }
}

/**
 * User-facing language toggle (fr|ar) — ERD §3.6, FR-I18N-01. Deliberately bilingual,
 * not trilingual, matching the shipped mobile scope (EPIC-06) and the User/
 * UserUpdateRequest openapi.yaml enums — see Phase 4 Implementation Plan §5 for the
 * documented BilingualText-vs-User.preferredLanguage drift this VO resolves against.
 */
export class LanguagePreference {
  private constructor(readonly code: LanguagePreferenceCode) {}

  static of(value: string): LanguagePreference {
    if (!VALID_CODES.includes(value as LanguagePreferenceCode)) {
      throw new InvalidLanguagePreferenceException(value);
    }
    return new LanguagePreference(value as LanguagePreferenceCode);
  }

  static readonly FR = new LanguagePreference('fr');
  static readonly AR = new LanguagePreference('ar');

  equals(other: LanguagePreference): boolean {
    return this.code === other.code;
  }
}
