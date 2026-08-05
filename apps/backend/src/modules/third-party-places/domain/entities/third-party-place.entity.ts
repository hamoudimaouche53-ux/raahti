import { DomainException, GeoPosition, Money } from '../../../../shared-kernel';
import { DeclaredStatus, StatusSource } from '../value-objects/declared-status.vo';
import { PlaceType } from '../value-objects/place-type.vo';
import { TagCode } from '../value-objects/tag.vo';

export class InvalidThirdPartyPlacePriceException extends DomainException {
  readonly code = 'THIRD_PARTY_PLACES_INVALID_PRICE';
  readonly status = 400;

  constructor(message: string) {
    super(message);
  }
}

export interface ThirdPartyPlaceProps {
  id: string;
  nameFr: string;
  nameAr: string;
  placeType: PlaceType;
  position: GeoPosition;
  isFree: boolean;
  price: Money | null;
  declaredStatus: DeclaredStatus;
  statusSource: StatusSource;
  tags: TagCode[];
  createdAt: Date;
  updatedAt: Date;
}

/** Aggregate root of the Third-Party Places bounded context (Domain Model §5, ERD §3.4). */
export class ThirdPartyPlace {
  private constructor(private readonly props: ThirdPartyPlaceProps) {}

  static restore(props: ThirdPartyPlaceProps): ThirdPartyPlace {
    if (!props.isFree && !props.price) {
      throw new InvalidThirdPartyPlacePriceException(`Third-party place ${props.id} is not free but has no price.`);
    }
    if (props.isFree && props.price) {
      throw new InvalidThirdPartyPlacePriceException(`Third-party place ${props.id} is free but has a price set.`);
    }
    return new ThirdPartyPlace(props);
  }

  get id(): string {
    return this.props.id;
  }

  get nameFr(): string {
    return this.props.nameFr;
  }

  get nameAr(): string {
    return this.props.nameAr;
  }

  get placeType(): PlaceType {
    return this.props.placeType;
  }

  get position(): GeoPosition {
    return this.props.position;
  }

  get isFree(): boolean {
    return this.props.isFree;
  }

  get price(): Money | null {
    return this.props.price;
  }

  get declaredStatus(): DeclaredStatus {
    return this.props.declaredStatus;
  }

  get statusSource(): StatusSource {
    return this.props.statusSource;
  }

  get tags(): readonly TagCode[] {
    return this.props.tags;
  }

  hasTag(tag: TagCode): boolean {
    return this.props.tags.includes(tag);
  }
}
