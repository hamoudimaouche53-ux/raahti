import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { VisitHistoryItem } from '../../application/visit-history-query.service';
import { MoneyDto } from './money.dto';

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

/** Mirrors identity/interface/dto/favorite-list-query.dto.ts's cursor-pagination convention exactly. */
export class VisitHistoryQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  cursor?: string;

  @ApiPropertyOptional({ default: DEFAULT_LIMIT })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(MAX_LIMIT)
  limit: number = DEFAULT_LIMIT;
}

/** Matches openapi.yaml components.schemas.VisitHistoryItem exactly. */
export class VisitHistoryItemResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty()
  placeName!: string;

  @ApiProperty({ format: 'date-time' })
  occurredAt!: string;

  @ApiProperty({ type: MoneyDto, nullable: true })
  amount!: MoneyDto | null;

  static fromResult(item: VisitHistoryItem): VisitHistoryItemResponseDto {
    const dto = new VisitHistoryItemResponseDto();
    dto.id = item.id;
    dto.placeName = item.placeName;
    dto.occurredAt = item.occurredAt.toISOString();
    dto.amount = item.amount ? MoneyDto.fromDomain(item.amount) : null;
    return dto;
  }
}

export class VisitHistoryListResponseDto {
  @ApiProperty({ type: [VisitHistoryItemResponseDto] })
  data!: VisitHistoryItemResponseDto[];

  @ApiProperty({ nullable: true, type: String })
  nextCursor!: string | null;
}
