import { DomainException } from '../../../../shared-kernel';

export class InvalidQrCodeException extends DomainException {
  readonly code = 'ACCESS_PAYMENT_INVALID_QR_CODE';
  readonly status = 400;

  constructor(message: string) {
    super(message);
  }
}

const MAX_LENGTH = 500;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/**
 * Wraps the raw scanned QR payload (RAH-DOC-005 §2.5 step 1). Neither the
 * ERD, domain-model.md, nor openapi.yaml specify the QR payload's encoding
 * — `AccessSessionCreateRequest.qrCodeScanned` is documented only as an
 * opaque `string`. V1 decision (flagged, not silently assumed): the QR
 * payload *is* the target cabin's UUID directly, with no separate
 * lookup/decoding table — the simplest reading consistent with "scan ->
 * availability check" being the very next step (RAH-DOC-005 §2.5). See
 * `toCabinId()`.
 */
export class QrCode {
  private constructor(private readonly value: string) {}

  static of(value: string): QrCode {
    if (!value || value.trim().length === 0) {
      throw new InvalidQrCodeException('QR code payload must not be empty.');
    }
    if (value.length > MAX_LENGTH) {
      throw new InvalidQrCodeException(`QR code payload exceeds the maximum length of ${MAX_LENGTH} characters.`);
    }
    return new QrCode(value);
  }

  /** V1 decision — see class doc comment. Throws InvalidQrCodeException if the payload isn't a well-formed UUID. */
  toCabinId(): string {
    if (!UUID_PATTERN.test(this.value)) {
      throw new InvalidQrCodeException(`"${this.value}" is not a valid cabin QR payload (expected a UUID).`);
    }
    return this.value;
  }

  get raw(): string {
    return this.value;
  }
}
