import { Body, Controller, Get, HttpCode, HttpStatus, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { FavoriteService } from '../../application/favorite.service';
import { JwtClaims } from '../../infrastructure/auth/jwt-claims';
import { CurrentUser } from '../decorators/current-user.decorator';
import { FavoriteCreateRequestDto, FavoriteListResponseDto, FavoriteResponseDto } from '../dto/favorite.dto';
import { FavoriteListQueryDto } from '../dto/favorite-list-query.dto';

/** GET/POST /users/me/favorites — openapi.yaml tag Identity (FR-USR-04). */
@ApiTags('Identity')
@ApiBearerAuth('bearerAuth')
@Controller('users/me/favorites')
export class FavoritesController {
  constructor(private readonly favoriteService: FavoriteService) {}

  @Get()
  async list(@CurrentUser() claims: JwtClaims, @Query() query: FavoriteListQueryDto): Promise<FavoriteListResponseDto> {
    const page = await this.favoriteService.list(claims.sub, query.cursor ?? null, query.limit);
    return {
      data: page.data.map((favorite) => FavoriteResponseDto.fromDomain(favorite)),
      nextCursor: page.nextCursor,
    };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@CurrentUser() claims: JwtClaims, @Body() body: FavoriteCreateRequestDto): Promise<FavoriteResponseDto> {
    const favorite = await this.favoriteService.create(claims.sub, body);
    return FavoriteResponseDto.fromDomain(favorite);
  }
}
