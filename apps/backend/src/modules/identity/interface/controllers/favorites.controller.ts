import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, ParseUUIDPipe, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { FavoriteService } from '../../application/favorite.service';
import { AuthenticatedPrincipal, CurrentUser } from '../../../../platform/auth';
import {
  FavoriteCreateRequestDto,
  FavoriteListResponseDto,
  FavoriteResponseDto,
  FavoriteUpdateRequestDto,
} from '../dto/favorite.dto';
import { FavoriteListQueryDto } from '../dto/favorite-list-query.dto';

/** GET/POST /users/me/favorites — openapi.yaml tag Identity (FR-USR-04). */
@ApiTags('Identity')
@ApiBearerAuth('bearerAuth')
@Controller('users/me/favorites')
export class FavoritesController {
  constructor(private readonly favoriteService: FavoriteService) {}

  @Get()
  async list(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Query() query: FavoriteListQueryDto,
  ): Promise<FavoriteListResponseDto> {
    const page = await this.favoriteService.list(principal.sub, query.cursor ?? null, query.limit);
    return {
      data: page.data.map((favorite) => FavoriteResponseDto.fromDomain(favorite)),
      nextCursor: page.nextCursor,
    };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Body() body: FavoriteCreateRequestDto,
  ): Promise<FavoriteResponseDto> {
    const favorite = await this.favoriteService.create(principal.sub, body);
    return FavoriteResponseDto.fromDomain(favorite);
  }

  @Delete(':favoriteId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('favoriteId', ParseUUIDPipe) favoriteId: string,
  ): Promise<void> {
    await this.favoriteService.remove(principal.sub, favoriteId);
  }

  @Patch(':favoriteId')
  async updateNotify(
    @CurrentUser() principal: AuthenticatedPrincipal,
    @Param('favoriteId', ParseUUIDPipe) favoriteId: string,
    @Body() body: FavoriteUpdateRequestDto,
  ): Promise<FavoriteResponseDto> {
    const favorite = await this.favoriteService.updateNotify(principal.sub, favoriteId, body.notifyOnAvailable);
    return FavoriteResponseDto.fromDomain(favorite);
  }
}
