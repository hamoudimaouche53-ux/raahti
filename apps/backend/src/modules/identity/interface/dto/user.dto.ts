import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsOptional } from 'class-validator';
import { User } from '../../domain/entities/user.entity';

/** Matches openapi.yaml components.schemas.User exactly. */
export class UserResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ nullable: true, type: String })
  email!: string | null;

  @ApiProperty({ nullable: true, type: String })
  phone!: string | null;

  @ApiProperty({ enum: ['fr', 'ar'] })
  preferredLanguage!: 'fr' | 'ar';

  @ApiProperty({ enum: ['none', 'pending', 'verified', 'rejected'] })
  diabeticVerificationStatus!: string;

  static fromDomain(user: User): UserResponseDto {
    const dto = new UserResponseDto();
    dto.id = user.id;
    dto.email = user.email;
    dto.phone = user.phone;
    dto.preferredLanguage = user.preferredLanguage.code;
    dto.diabeticVerificationStatus = user.diabeticVerificationStatus;
    return dto;
  }
}

/** Matches openapi.yaml components.schemas.UserUpdateRequest exactly (FR-I18N-01). */
export class UserUpdateRequestDto {
  @ApiProperty({ enum: ['fr', 'ar'], required: false })
  @IsOptional()
  @IsIn(['fr', 'ar'])
  preferredLanguage?: 'fr' | 'ar';
}
