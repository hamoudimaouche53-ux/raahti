import { ApiProperty } from '@nestjs/swagger';
import { Money } from '../../../../shared-kernel';

/** Matches openapi.yaml components.schemas.Money. */
export class MoneyDto {
  @ApiProperty()
  amount!: string;

  @ApiProperty()
  currency!: string;

  static fromDomain(money: Money): MoneyDto {
    const dto = new MoneyDto();
    dto.amount = money.toDecimalString();
    dto.currency = money.currency;
    return dto;
  }
}
