import { DomainException, GeoPosition } from '../../../../shared-kernel';
import { StationConfiguration } from '../value-objects/station-configuration.vo';
import { StationStatus } from '../value-objects/station-status.vo';
import { Cabin } from './cabin.entity';
import { SlatokiTent } from './slatoki-tent.entity';

export class CabinStationMismatchException extends DomainException {
  readonly code = 'STATION_NETWORK_CABIN_STATION_MISMATCH';
  readonly status = 400;

  constructor(cabinId: string, cabinStationId: string, stationId: string) {
    super(`Cabin ${cabinId} belongs to station ${cabinStationId}, not station ${stationId}.`);
  }
}

export class SlatokiTentStationMismatchException extends DomainException {
  readonly code = 'STATION_NETWORK_SLATOKI_TENT_STATION_MISMATCH';
  readonly status = 400;

  constructor(tentId: string, tentStationId: string, stationId: string) {
    super(`Slatoki tent ${tentId} belongs to station ${tentStationId}, not station ${stationId}.`);
  }
}

export type CabinPricingMix = 'all_free' | 'all_paid' | 'mixed' | 'no_cabins';

export interface StationProps {
  id: string;
  code: string;
  configuration: StationConfiguration;
  position: GeoPosition;
  status: StationStatus;
  cabinCapacity: number;
  tankCapacityLiters: number;
  installedAt: Date;
  createdAt: Date;
  updatedAt: Date;
  cabins: Cabin[];
  slatokiTent: SlatokiTent | null;
}

/**
 * Aggregate root of the Station Network bounded context (Domain Model §3).
 * Aggregate boundary includes its Cabin entities and, where present, its
 * SlatokiTent — both invariants ("belongs to exactly one/at most one
 * Station") are enforced at construction here, not left to the caller.
 */
export class Station {
  private constructor(private readonly props: StationProps) {}

  static restore(props: StationProps): Station {
    for (const cabin of props.cabins) {
      if (cabin.stationId !== props.id) {
        throw new CabinStationMismatchException(cabin.id, cabin.stationId, props.id);
      }
    }
    if (props.slatokiTent && props.slatokiTent.stationId !== props.id) {
      throw new SlatokiTentStationMismatchException(props.slatokiTent.id, props.slatokiTent.stationId, props.id);
    }
    return new Station(props);
  }

  get id(): string {
    return this.props.id;
  }

  get code(): string {
    return this.props.code;
  }

  get configuration(): StationConfiguration {
    return this.props.configuration;
  }

  get position(): GeoPosition {
    return this.props.position;
  }

  get status(): StationStatus {
    return this.props.status;
  }

  get cabinCapacity(): number {
    return this.props.cabinCapacity;
  }

  get tankCapacityLiters(): number {
    return this.props.tankCapacityLiters;
  }

  get installedAt(): Date {
    return this.props.installedAt;
  }

  get cabins(): readonly Cabin[] {
    return this.props.cabins;
  }

  get slatokiTent(): SlatokiTent | null {
    return this.props.slatokiTent;
  }

  get hasSlatokiTent(): boolean {
    return this.props.slatokiTent !== null;
  }

  /** Drives pinColor derivation (Facilities Pass 3) — a station's cabins aren't uniformly free or paid, so a single isFree boolean can't represent it. */
  cabinPricingMix(): CabinPricingMix {
    if (this.props.cabins.length === 0) {
      return 'no_cabins';
    }
    const allFree = this.props.cabins.every((cabin) => !cabin.isPaid);
    if (allFree) {
      return 'all_free';
    }
    const allPaid = this.props.cabins.every((cabin) => cabin.isPaid);
    return allPaid ? 'all_paid' : 'mixed';
  }
}
