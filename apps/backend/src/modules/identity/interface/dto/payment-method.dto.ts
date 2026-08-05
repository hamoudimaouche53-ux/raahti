import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsString } from 'class-validator';
import { PaymentMethod } from '../../domain/entities/payment-method.entity';

const METHOD_TYPES = ['card', 'mobile_wallet', 'subscription'] as const;

/** Matches openapi.yaml components.schemas.PaymentMethodCreateRequest exactly. */
export class PaymentMethodCreateRequestDto {
  @ApiProperty({ enum: METHOD_TYPES })
  @IsIn(METHOD_TYPES)
  methodType!: string;

  @ApiProperty({ description: 'Client-side-obtained provider token.' })
  @IsString()
  @IsNotEmpty()
  providerToken!: string;
}

/** Matches openapi.yaml components.schemas.PaymentMethod exactly. */
export class PaymentMethodResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: METHOD_TYPES })
  methodType!: string;

  @ApiProperty({ description: 'Opaque tokenized reference — never raw PAN.' })
  providerRef!: string;

  @ApiProperty()
  isDefault!: boolean;

  static fromDomain(method: PaymentMethod): PaymentMethodResponseDto {
    const dto = new PaymentMethodResponseDto();
    dto.id = method.id;
    dto.methodType = method.methodType;
    dto.providerRef = method.providerRef;
    dto.isDefault = method.isDefault;
    return dto;
  }
}
