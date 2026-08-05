import { DomainException, LanguagePreference } from '../../../../shared-kernel';
import {
  DEFAULT_DIABETIC_VERIFICATION_STATUS,
  DiabeticVerificationStatus,
} from '../value-objects/diabetic-verification-status.vo';

export class MissingContactMethodException extends DomainException {
  readonly code = 'IDENTITY_USER_MISSING_CONTACT_METHOD';
  readonly status = 400;

  constructor() {
    super('A User must have at least one contact method (email or phone) once persisted.');
  }
}

export interface UserProps {
  id: string;
  email: string | null;
  phone: string | null;
  preferredLanguage: LanguagePreference;
  diabeticVerificationStatus: DiabeticVerificationStatus;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Aggregate root of the Identity & Access bounded context (Domain Model §2).
 * Guest usage (no account) is the absence of a User row entirely (FR-USR-01) —
 * this class only ever represents an account-holding user.
 */
export class User {
  private constructor(private readonly props: UserProps) {}

  static create(props: {
    id: string;
    email?: string | null;
    phone?: string | null;
    preferredLanguage?: LanguagePreference;
    diabeticVerificationStatus?: DiabeticVerificationStatus;
    isActive?: boolean;
    createdAt?: Date;
    updatedAt?: Date;
  }): User {
    const email = props.email ?? null;
    const phone = props.phone ?? null;
    if (!email && !phone) {
      throw new MissingContactMethodException();
    }
    const now = props.createdAt ?? new Date();
    return new User({
      id: props.id,
      email,
      phone,
      preferredLanguage: props.preferredLanguage ?? LanguagePreference.FR,
      diabeticVerificationStatus: props.diabeticVerificationStatus ?? DEFAULT_DIABETIC_VERIFICATION_STATUS,
      isActive: props.isActive ?? true,
      createdAt: now,
      updatedAt: props.updatedAt ?? now,
    });
  }

  get id(): string {
    return this.props.id;
  }

  get email(): string | null {
    return this.props.email;
  }

  get phone(): string | null {
    return this.props.phone;
  }

  get preferredLanguage(): LanguagePreference {
    return this.props.preferredLanguage;
  }

  get diabeticVerificationStatus(): DiabeticVerificationStatus {
    return this.props.diabeticVerificationStatus;
  }

  get isActive(): boolean {
    return this.props.isActive;
  }
}
