/**
 * A single walking route between two points (Domain Model — Routing).
 * Provider-agnostic: whichever [RouteProvider] produced this (OSRM today,
 * any other routing engine later) normalizes its response to this shape —
 * nothing outside infrastructure/ ever sees a provider-specific payload.
 */
export interface Route {
  /** Encoded polyline (Google/OSRM precision-5 algorithm) — decoded client-side. */
  readonly polyline: string;
  readonly distanceMeters: number;
  readonly durationSeconds: number;
}
