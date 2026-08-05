import { GeoPosition } from '../../../../shared-kernel';

/**
 * Domain Model §4 — "stateless: computes bearing to Mecca from a GeoPosition".
 * Documented as a Slatoki-owned domain service for architectural completeness
 * with domain-model.md, but deliberately NOT wired to any controller/endpoint:
 * openapi.yaml's /slatoki/places description is explicit that "Qibla bearing
 * is computed client-side (device compass + great-circle formula) and is
 * intentionally NOT a server endpoint". Kept here, tested, unused by any
 * controller — matching the documented architecture exactly rather than
 * silently dropping a documented domain responsibility or inventing an
 * endpoint the contract doesn't define.
 */
export class QiblaDirectionCalculator {
  /** Kaaba, Mecca (WGS84) — RAH-DOC-005 §2.3. */
  private static readonly MECCA = GeoPosition.of(21.4225, 39.8262);

  /** Initial great-circle bearing in degrees [0, 360), measured clockwise from true north. */
  static bearingFrom(position: GeoPosition): number {
    const lat1 = toRadians(position.lat);
    const lat2 = toRadians(QiblaDirectionCalculator.MECCA.lat);
    const deltaLng = toRadians(QiblaDirectionCalculator.MECCA.lng - position.lng);

    const y = Math.sin(deltaLng) * Math.cos(lat2);
    const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(deltaLng);
    const bearing = toDegrees(Math.atan2(y, x));

    return (bearing + 360) % 360;
  }
}

function toRadians(degrees: number): number {
  return (degrees * Math.PI) / 180;
}

function toDegrees(radians: number): number {
  return (radians * 180) / Math.PI;
}
