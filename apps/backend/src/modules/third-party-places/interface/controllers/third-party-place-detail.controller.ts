import { Controller, Get, Param, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../../../platform/auth';
import { ThirdPartyPlaceQueryService } from '../../application/third-party-place-query.service';
import { ThirdPartyPlaceDetailDto } from '../dto/third-party-place-detail.dto';

/** GET /third-party-places/{placeId} — openapi.yaml tag Places, security: [] (FR-USR-01 guest usage). */
@ApiTags('Places')
@Controller('third-party-places')
export class ThirdPartyPlaceDetailController {
  constructor(private readonly thirdPartyPlaceQueryService: ThirdPartyPlaceQueryService) {}

  @Public()
  @Get(':placeId')
  async getDetail(@Param('placeId', ParseUUIDPipe) placeId: string): Promise<ThirdPartyPlaceDetailDto> {
    const [place, rating] = await Promise.all([
      this.thirdPartyPlaceQueryService.getById(placeId),
      this.thirdPartyPlaceQueryService.getRatingAggregate(placeId),
    ]);
    return ThirdPartyPlaceDetailDto.fromDomain(place, rating);
  }
}
