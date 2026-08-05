import { Body, Controller, Get, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserProfileService } from '../../application/user-profile.service';
import { JwtClaims } from '../../infrastructure/auth/jwt-claims';
import { CurrentUser } from '../decorators/current-user.decorator';
import { UserResponseDto, UserUpdateRequestDto } from '../dto/user.dto';

/** GET/PATCH /users/me — openapi.yaml tag Identity. */
@ApiTags('Identity')
@ApiBearerAuth('bearerAuth')
@Controller('users/me')
export class UserProfileController {
  constructor(private readonly userProfileService: UserProfileService) {}

  @Get()
  async getProfile(@CurrentUser() claims: JwtClaims): Promise<UserResponseDto> {
    const user = await this.userProfileService.getOrCreateCurrentUser(claims);
    return UserResponseDto.fromDomain(user);
  }

  @Patch()
  async updateProfile(@CurrentUser() claims: JwtClaims, @Body() body: UserUpdateRequestDto): Promise<UserResponseDto> {
    if (!body.preferredLanguage) {
      const user = await this.userProfileService.getOrCreateCurrentUser(claims);
      return UserResponseDto.fromDomain(user);
    }
    const user = await this.userProfileService.updateLanguagePreference(claims, body.preferredLanguage);
    return UserResponseDto.fromDomain(user);
  }
}
