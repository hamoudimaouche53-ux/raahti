import { ApiProperty } from '@nestjs/swagger';
import { MyReviewListItem } from '../../my-reviews-query.service';
import { BilingualTextDto } from './bilingual-text.dto';

/** Matches openapi.yaml components.schemas.MyReviewListItem exactly (GET /users/me/reviews, EPIC-05 US-05.2). */
export class MyReviewListItemDto {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: ['station', 'third-party-place'] })
  placeType!: 'station' | 'third-party-place';

  @ApiProperty({ format: 'uuid' })
  placeId!: string;

  @ApiProperty({ type: BilingualTextDto })
  placeName!: BilingualTextDto;

  @ApiProperty()
  rating!: number;

  @ApiProperty({ nullable: true })
  comment!: string | null;

  @ApiProperty({ format: 'date-time' })
  createdAt!: string;

  static fromItem(item: MyReviewListItem): MyReviewListItemDto {
    const dto = new MyReviewListItemDto();
    dto.id = item.id;
    dto.placeType = item.placeType;
    dto.placeId = item.placeId;
    dto.placeName = item.placeName;
    dto.rating = item.rating;
    dto.comment = item.comment;
    dto.createdAt = item.createdAt.toISOString();
    return dto;
  }
}
