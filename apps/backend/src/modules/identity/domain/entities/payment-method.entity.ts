import { PaymentMethodType } from '../value-objects/payment-method-type.vo';

export interface PaymentMethodProps {
  id: string;
  userId: string;
  methodType: PaymentMethodType;
  providerRef: string;
  isDefault: boolean;
  createdAt: Date;
}

/**
 * §2.6 saved payment methods. Only ever holds a provider-issued token
 * (`providerRef`) — never raw card data (ADR-0014, NFR-SEC-03). The token is
 * obtained client-side via the eventual payment SDK; this entity treats it as
 * opaque.
 */
export class PaymentMethod {
  private constructor(private readonly props: PaymentMethodProps) {}

  static create(params: {
    id: string;
    userId: string;
    methodType: PaymentMethodType;
    providerRef: string;
    isDefault?: boolean;
  }): PaymentMethod {
    return new PaymentMethod({
      id: params.id,
      userId: params.userId,
      methodType: params.methodType,
      providerRef: params.providerRef,
      isDefault: params.isDefault ?? false,
      createdAt: new Date(),
    });
  }

  static restore(props: PaymentMethodProps): PaymentMethod {
    return new PaymentMethod(props);
  }

  get id(): string {
    return this.props.id;
  }

  get userId(): string {
    return this.props.userId;
  }

  get methodType(): PaymentMethodType {
    return this.props.methodType;
  }

  get providerRef(): string {
    return this.props.providerRef;
  }

  get isDefault(): boolean {
    return this.props.isDefault;
  }
}
