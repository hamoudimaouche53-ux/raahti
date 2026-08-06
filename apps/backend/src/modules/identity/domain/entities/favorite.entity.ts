import { DomainException } from '../../../../shared-kernel';

export class InvalidFavoriteTargetException extends DomainException {
  readonly code = 'IDENTITY_INVALID_FAVORITE_TARGET';
  readonly status = 400;

  constructor() {
    super('A Favorite must target exactly one of stationId or thirdPartyPlaceId, not both or neither.');
  }
}

export interface FavoriteProps {
  id: string;
  userId: string;
  stationId: string | null;
  thirdPartyPlaceId: string | null;
  notifyOnAvailable: boolean;
  createdAt: Date;
}

/**
 * ERD §3.16 — polymorphic over Station XOR ThirdPartyPlace (same pattern as
 * Review, ERD §3.15). The DB-level CHECK constraint isn't live yet (see
 * prisma/README.md) — this is the primary invariant guard until it is.
 */
export class Favorite {
  private constructor(private props: FavoriteProps) {}

  static create(params: {
    id: string;
    userId: string;
    stationId?: string | null;
    thirdPartyPlaceId?: string | null;
    notifyOnAvailable?: boolean;
  }): Favorite {
    const stationId = params.stationId ?? null;
    const thirdPartyPlaceId = params.thirdPartyPlaceId ?? null;
    const targetCount = [stationId, thirdPartyPlaceId].filter((value) => value !== null).length;
    if (targetCount !== 1) {
      throw new InvalidFavoriteTargetException();
    }
    return new Favorite({
      id: params.id,
      userId: params.userId,
      stationId,
      thirdPartyPlaceId,
      notifyOnAvailable: params.notifyOnAvailable ?? false,
      createdAt: new Date(),
    });
  }

  static restore(props: FavoriteProps): Favorite {
    return new Favorite(props);
  }

  get id(): string {
    return this.props.id;
  }

  get userId(): string {
    return this.props.userId;
  }

  get stationId(): string | null {
    return this.props.stationId;
  }

  get thirdPartyPlaceId(): string | null {
    return this.props.thirdPartyPlaceId;
  }

  get notifyOnAvailable(): boolean {
    return this.props.notifyOnAvailable;
  }

  /**
   * Mutator for PATCH /users/me/favorites/{favoriteId} (FR-USR-04) — `props`
   * was made mutable (readonly dropped) the same way Station Network's
   * `Cabin` entity does for its own `changeOccupancy` mutator.
   */
  setNotifyOnAvailable(value: boolean): void {
    this.props = { ...this.props, notifyOnAvailable: value };
  }
}
