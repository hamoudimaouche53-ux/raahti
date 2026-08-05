import { GeoPosition } from '../../../../shared-kernel';
import { QiblaDirectionCalculator } from './qibla-direction-calculator';

describe('QiblaDirectionCalculator', () => {
  it('returns a bearing due south (180°) from a point due north of Mecca at the same longitude', () => {
    // Same longitude as the Kaaba, further north — great-circle bearing collapses to due south.
    const point = GeoPosition.of(40, 39.8262);
    expect(QiblaDirectionCalculator.bearingFrom(point)).toBeCloseTo(180, 6);
  });

  it('returns a bearing in [0, 360) for an arbitrary point (Algiers)', () => {
    const algiers = GeoPosition.of(36.7538, 3.0588);
    const bearing = QiblaDirectionCalculator.bearingFrom(algiers);
    expect(bearing).toBeGreaterThanOrEqual(0);
    expect(bearing).toBeLessThan(360);
  });

  it('points roughly east-southeast from Algiers (Mecca is east and slightly south)', () => {
    const algiers = GeoPosition.of(36.7538, 3.0588);
    const bearing = QiblaDirectionCalculator.bearingFrom(algiers);
    // Sanity band, not an exact value: Mecca is east-southeast of Algiers.
    expect(bearing).toBeGreaterThan(90);
    expect(bearing).toBeLessThan(180);
  });

  it('does not throw when evaluated at the Kaaba itself', () => {
    const mecca = GeoPosition.of(21.4225, 39.8262);
    expect(() => QiblaDirectionCalculator.bearingFrom(mecca)).not.toThrow();
  });
});
