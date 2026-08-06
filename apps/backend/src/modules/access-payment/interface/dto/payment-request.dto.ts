import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsUUID } from 'class-validator';

/** Matches openapi.yaml components.schemas.PaymentRequest exactly. */
export class PaymentRequestDto {
  @ApiPropertyOptional({ format: 'uuid', nullable: true, description: 'Omit for free cabins.' })
  @IsOptional()
  @IsUUID()
  paymentMethodId?: string | null;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  applyEmergencyDiscount?: boolean;
}
