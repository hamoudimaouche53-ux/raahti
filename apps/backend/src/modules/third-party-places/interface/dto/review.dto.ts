import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { ThirdPartyPlaceReview } from '../../domain/entities/review.entity';

/** Matches openapi.yaml components.schemas.ReviewCreateRequest exactly (FR-PLC-01). */
export class ReviewCreateRequestDto {
  @ApiProperty({ minimum: 1, maximum: 5 })
  @IsInt()
  @Min(1)
  @Max(5)
  rating!: number;

  @ApiProperty({ required: false, nullable: true })
  @IsOptional()
  @IsString()
  comment?: string | null;
}

/** Matches openapi.yaml components.schemas.ReviewUpdateRequest exactly — same required shape as ReviewCreateRequest (FR-PLC-01 / EPIC-05 US-05.2). */
export class ReviewUpdateRequestDto extends ReviewCreateRequestDto {}

/** Matches openapi.yaml components.schemas.Review exactly. */
export class ReviewResponseDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty()
  rating!: number;

  @ApiProperty({ nullable: true })
  comment!: string | null;

  @ApiProperty({ format: 'date-time' })
  createdAt!: string;

  static fromDomain(review: ThirdPartyPlaceReview): ReviewResponseDto {
    const dto = new ReviewResponseDto();
    dto.id = review.id;
    dto.rating = review.rating;
    dto.comment = review.comment;
    dto.createdAt = review.createdAt.toISOString();
    return dto;
  }
}
