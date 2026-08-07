import { ApiProperty } from '@nestjs/swagger';
import { Route } from '../../domain/route';

/** Matches openapi.yaml components.schemas.Route. */
export class RouteDto {
  @ApiProperty({ description: 'Encoded polyline (precision 5) — decode client-side.' })
  polyline!: string;

  @ApiProperty()
  distanceMeters!: number;

  @ApiProperty()
  durationSeconds!: number;

  static fromRoute(route: Route): RouteDto {
    const dto = new RouteDto();
    dto.polyline = route.polyline;
    dto.distanceMeters = route.distanceMeters;
    dto.durationSeconds = route.durationSeconds;
    return dto;
  }
}
