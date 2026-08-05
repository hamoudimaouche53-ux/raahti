import { DomainException, Money } from '../../../../shared-kernel';
import { CabinType } from '../value-objects/cabin-type.vo';
import { OccupancyStatus } from '../value-objects/occupancy-status.vo';

export class InvalidCabinPriceException extends DomainException {
  readonly code = 'STATION_NETWORK_INVALID_CABIN_PRICE';
  readonly status = 400;

  constructor(message: string) {
    super(message);
  }
}

export interface CabinProps {
  id: string;
  stationId: string;
  code: string;
  type: CabinType;
  occupancyStatus: OccupancyStatus;
  isPaid: boolean;
  price: Money | null;
}

/** ERD §3.2 — entity within the Station aggregate (Domain Model §3). A Cabin always belongs to exactly one Station (enforced by construction — always created with a stationId). */
export class Cabin {
  private constructor(private readonly props: CabinProps) {}

  static restore(props: CabinProps): Cabin {
    if (props.isPaid && !props.price) {
      throw new InvalidCabinPriceException(`Cabin ${props.id} is paid but has no price.`);
    }
    if (!props.isPaid && props.price) {
      throw new InvalidCabinPriceException(`Cabin ${props.id} is free but has a price set.`);
    }
    return new Cabin(props);
  }

  get id(): string {
    return this.props.id;
  }

  get stationId(): string {
    return this.props.stationId;
  }

  get code(): string {
    return this.props.code;
  }

  get type(): CabinType {
    return this.props.type;
  }

  get occupancyStatus(): OccupancyStatus {
    return this.props.occupancyStatus;
  }

  get isPaid(): boolean {
    return this.props.isPaid;
  }

  get price(): Money | null {
    return this.props.price;
  }
}
