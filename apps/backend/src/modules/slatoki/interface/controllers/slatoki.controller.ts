import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GeoPosition } from '../../../../shared-kernel';
import { Public } from '../../../../platform/auth';
import { SlatokiQueryService } from '../../application/slatoki-query.service';
import { assertPrayerFacilityFilter, PrayerFacilityFilter } from '../../domain/value-objects/prayer-facility-filter.vo';
import { SlatokiPlaceSummaryDto } from '../dto/slatoki-place-summary.dto';
import { SlatokiPlacesQueryDto } from '../dto/slatoki-places-query.dto';

/** GET /slatoki/places — openapi.yaml tag Slatoki, security: [] (FR-USR-01 guest usage). */
@ApiTags('Slatoki')
@Controller('slatoki')
export class SlatokiController {
  constructor(private readonly slatokiQueryService: SlatokiQueryService) {}

  @Public()
  @Get('places')
  async searchPlaces(@Query() query: SlatokiPlacesQueryDto): Promise<{ data: SlatokiPlaceSummaryDto[] }> {
    let filter: PrayerFacilityFilter | undefined;
    if (query.filter) {
      assertPrayerFacilityFilter(query.filter);
      filter = query.filter;
    }

    const items = await this.slatokiQueryService.searchPlaces({
      position: GeoPosition.of(query.lat, query.lng),
      filter,
    });
    return { data: items.map((item) => SlatokiPlaceSummaryDto.fromSearchItem(item)) };
  }
}
