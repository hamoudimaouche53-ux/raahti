import { ApiProperty } from '@nestjs/swagger';
import { Cabin } from '../../domain/entities/cabin.entity';
import { MoneyDto } from './money.dto';

/** Matches openapi.yaml components.schemas.Cabin exactly. */
export class CabinDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty()
  code!: string;

  @ApiProperty({ enum: ['H', 'F', 'Slatoki', 'PMR'] })
  type!: string;

  @ApiProperty({ enum: ['free', 'occupied', 'out_of_service'] })
  occupancyStatus!: string;

  @ApiProperty()
  isPaid!: boolean;

  @ApiProperty({ type: MoneyDto, nullable: true })
  price!: MoneyDto | null;

  static fromDomain(cabin: Cabin): CabinDto {
    const dto = new CabinDto();
    dto.id = cabin.id;
    dto.code = cabin.code;
    dto.type = cabin.type;
    dto.occupancyStatus = cabin.occupancyStatus;
    dto.isPaid = cabin.isPaid;
    dto.price = cabin.price ? MoneyDto.fromDomain(cabin.price) : null;
    return dto;
  }
}
