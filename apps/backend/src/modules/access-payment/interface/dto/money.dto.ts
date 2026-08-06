import { ApiProperty } from '@nestjs/swagger';
import { Money } from '../../../../shared-kernel';

/**
 * Matches openapi.yaml components.schemas.Money. A near-identical
 * `MoneyDto` already exists at
 * `station-network/interface/dto/money.dto.ts`, but this module's
 * interface/ layer may not import station-network's interface/ layer at
 * all (eslint zone: only station-network's exported application/ service is
 * a sanctioned dependency) — so a small local copy lives here instead,
 * mirroring the same convention rather than reaching across the boundary.
 */
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
