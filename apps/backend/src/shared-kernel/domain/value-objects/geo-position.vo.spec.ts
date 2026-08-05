import { GeoPosition, InvalidGeoPositionException } from './geo-position.vo';

describe('GeoPosition', () => {
  it('accepts a valid lat/lng pair', () => {
    const pos = GeoPosition.of(36.7538, 3.0588); // Algiers
    expect(pos.lat).toBe(36.7538);
    expect(pos.lng).toBe(3.0588);
  });

  it.each([-91, 91, NaN, Infinity])('rejects out-of-range latitude %p', (lat) => {
    expect(() => GeoPosition.of(lat, 0)).toThrow(InvalidGeoPositionException);
  });

  it.each([-181, 181, NaN, -Infinity])('rejects out-of-range longitude %p', (lng) => {
    expect(() => GeoPosition.of(0, lng)).toThrow(InvalidGeoPositionException);
  });
});
