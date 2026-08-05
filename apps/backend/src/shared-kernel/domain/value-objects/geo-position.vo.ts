import { DomainException } from '../domain-exception';

export class InvalidGeoPositionException extends DomainException {
  readonly code = 'SHARED_KERNEL_INVALID_GEO_POSITION';
  readonly status = 400;

  constructor(message: string) {
    super(message);
  }
}

/** lat/lng point (Domain Model §3) — GeoJSON [lng, lat] order is an API/Infrastructure
 * transport concern (api-architecture.md §4), not part of this VO's shape. */
export class GeoPosition {
  private constructor(
    readonly lat: number,
    readonly lng: number,
  ) {}

  static of(lat: number, lng: number): GeoPosition {
    if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
      throw new InvalidGeoPositionException(`Latitude ${lat} out of range [-90, 90].`);
    }
    if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
      throw new InvalidGeoPositionException(`Longitude ${lng} out of range [-180, 180].`);
    }
    return new GeoPosition(lat, lng);
  }
}
