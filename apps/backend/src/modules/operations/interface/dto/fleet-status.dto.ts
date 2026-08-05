import { ApiProperty } from '@nestjs/swagger';
import { FleetCabinStatus, StationFleetStatus } from '../../application/fleet-status.service';

/** Matches openapi.yaml components.schemas.Cabin exactly (this module's own projection, not station-network's CabinDto — see module-dependency-diagram.md §3). */
export class FleetCabinStatusDto {
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

  @ApiProperty({ nullable: true })
  price!: { amount: string; currency: string } | null;

  static fromDomain(cabin: FleetCabinStatus): FleetCabinStatusDto {
    const dto = new FleetCabinStatusDto();
    dto.id = cabin.id;
    dto.code = cabin.code;
    dto.type = cabin.type;
    dto.occupancyStatus = cabin.occupancyStatus;
    dto.isPaid = cabin.isPaid;
    dto.price = cabin.price ? { amount: cabin.price.toDecimalString(), currency: cabin.price.currency } : null;
    return dto;
  }
}

/** Matches openapi.yaml components.schemas.StationFleetStatus exactly. */
export class StationFleetStatusDto {
  @ApiProperty({ format: 'uuid' })
  stationId!: string;

  @ApiProperty({ nullable: true })
  batteryLevel!: number | null;

  @ApiProperty({ nullable: true })
  waterLevel!: number | null;

  @ApiProperty({ type: [FleetCabinStatusDto] })
  cabins!: FleetCabinStatusDto[];

  @ApiProperty()
  activeAlertCount!: number;

  static fromDomain(status: StationFleetStatus): StationFleetStatusDto {
    const dto = new StationFleetStatusDto();
    dto.stationId = status.stationId;
    dto.batteryLevel = status.batteryLevel;
    dto.waterLevel = status.waterLevel;
    dto.cabins = status.cabins.map((cabin) => FleetCabinStatusDto.fromDomain(cabin));
    dto.activeAlertCount = status.activeAlertCount;
    return dto;
  }
}
