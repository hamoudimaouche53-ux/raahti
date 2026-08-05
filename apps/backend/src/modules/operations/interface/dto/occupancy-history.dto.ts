import { ApiProperty } from '@nestjs/swagger';
import { IsDateString } from 'class-validator';
import { OccupancyHistoryResult } from '../../application/occupancy-history.service';

/** GET /ops/stations/{stationId}/occupancy-history — matches openapi.yaml's query parameters exactly (both required). */
export class OccupancyHistoryQueryDto {
  @ApiProperty({ format: 'date' })
  @IsDateString()
  from!: string;

  @ApiProperty({ format: 'date' })
  @IsDateString()
  to!: string;
}

class OccupancyHistoryPointDto {
  @ApiProperty({ format: 'date-time' })
  timestamp!: string;

  @ApiProperty()
  occupiedCabinCount!: number;
}

/** Matches openapi.yaml components.schemas.OccupancyHistorySeries exactly. */
export class OccupancyHistorySeriesDto {
  @ApiProperty({ format: 'uuid' })
  stationId!: string;

  @ApiProperty({ type: [OccupancyHistoryPointDto] })
  points!: OccupancyHistoryPointDto[];

  static fromDomain(result: OccupancyHistoryResult): OccupancyHistorySeriesDto {
    const dto = new OccupancyHistorySeriesDto();
    dto.stationId = result.stationId;
    dto.points = result.points.map((point) => ({
      timestamp: point.timestamp.toISOString(),
      occupiedCabinCount: point.occupiedCabinCount,
    }));
    return dto;
  }
}
