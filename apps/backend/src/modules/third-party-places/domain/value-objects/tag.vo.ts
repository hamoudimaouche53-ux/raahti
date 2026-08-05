import { DomainException } from '../../../../shared-kernel';

/** ERD §3.5 (Tag) / §3.6 (Third-Party Place Tag). */
export type TagCode = 'women_confirmed' | 'wudu' | 'pmr' | 'prayer' | 'open_now';

const VALID: readonly TagCode[] = ['women_confirmed', 'wudu', 'pmr', 'prayer', 'open_now'];

export class InvalidTagCodeException extends DomainException {
  readonly code = 'THIRD_PARTY_PLACES_INVALID_TAG_CODE';
  readonly status = 400;

  constructor(value: string) {
    super(`"${value}" is not a recognized tag code (expected women_confirmed|wudu|pmr|prayer|open_now).`);
  }
}

export function assertTagCode(value: string): asserts value is TagCode {
  if (!VALID.includes(value as TagCode)) {
    throw new InvalidTagCodeException(value);
  }
}
