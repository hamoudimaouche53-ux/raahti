import { Inject, Injectable } from '@nestjs/common';
import { GeoPosition } from '../../../shared-kernel';
import { ThirdPartyPlace } from '../domain/entities/third-party-place.entity';
import {
  THIRD_PARTY_PLACE_REPOSITORY,
  ThirdPartyPlaceRepository,
} from '../domain/ports/third-party-place.repository';
import {
  THIRD_PARTY_PLACE_REVIEW_REPOSITORY,
  ThirdPartyPlaceRatingAggregate,
  ThirdPartyPlaceReviewRepository,
} from '../domain/ports/third-party-place-review.repository';
import { PlaceFilterType } from '../domain/value-objects/place-filter-type.vo';
import { deriveThirdPartyPlacePinColorFromSearchResult, PinColor } from './pin-color';
import { ThirdPartyPlaceNotFoundException } from './third-party-place-not-found.exception';

export interface ThirdPartyPlacePlaceSearchItem {
  id: string;
  placeKind: 'third_party_place';
  name: { fr: string; ar: string; en: string };
  position: { lat: number; lng: number };
  pinColor: PinColor;
  distanceMeters: number;
  isFree: boolean;
  averageRating: number | null;
  reviewCount: number;
  tags: string[];
}

export interface ThirdPartyPlacePlaceSearchPage {
  data: ThirdPartyPlacePlaceSearchItem[];
  nextCursor: string | null;
}

export interface ThirdPartyPlaceNearbySearchCriteria {
  position: GeoPosition;
  radiusMeters: number;
  types: PlaceFilterType[];
  query?: string;
  cursor?: string | null;
  limit: number;
}

/** Exported application-layer query surface for this module (module-dependency-diagram.md §5 rule 1). */
@Injectable()
export class ThirdPartyPlaceQueryService {
  constructor(
    @Inject(THIRD_PARTY_PLACE_REPOSITORY) private readonly thirdPartyPlaceRepository: ThirdPartyPlaceRepository,
    @Inject(THIRD_PARTY_PLACE_REVIEW_REPOSITORY)
    private readonly thirdPartyPlaceReviewRepository: ThirdPartyPlaceReviewRepository,
  ) {}

  async getById(id: string): Promise<ThirdPartyPlace> {
    const place = await this.thirdPartyPlaceRepository.findById(id);
    if (!place) {
      throw new ThirdPartyPlaceNotFoundException(id);
    }
    return place;
  }

  /** ERD §3.4 note — derived read-model, computed alongside (not stored on) the ThirdPartyPlace entity. */
  async getRatingAggregate(thirdPartyPlaceId: string): Promise<ThirdPartyPlaceRatingAggregate> {
    return this.thirdPartyPlaceReviewRepository.aggregateByThirdPartyPlaceId(thirdPartyPlaceId);
  }

  /** Backing GET /places/nearby (via the Places composition layer, ADR-0029). */
  async searchNearby(criteria: ThirdPartyPlaceNearbySearchCriteria): Promise<ThirdPartyPlacePlaceSearchPage> {
    const page = await this.thirdPartyPlaceRepository.searchNearby(criteria);
    return {
      data: page.data.map((result) => ({
        id: result.id,
        placeKind: 'third_party_place' as const,
        name: { fr: result.nameFr, ar: result.nameAr, en: result.nameFr },
        position: { lat: result.position.lat, lng: result.position.lng },
        pinColor: deriveThirdPartyPlacePinColorFromSearchResult(result),
        distanceMeters: result.distanceMeters,
        isFree: result.isFree,
        averageRating: result.averageRating,
        reviewCount: result.reviewCount,
        tags: result.tags,
      })),
      nextCursor: page.nextCursor,
    };
  }
}
