# ADR-0025: Qibla Compass Sensor Package — `flutter_compass`

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-01 |
| **Deciders** | Engineering team |
| **Phase** | Phase 3 — Flutter Implementation, EPIC-02 US-02.1.2 |
| **Related** | [ADR-0019 — Map rendering and geolocation dependencies](./0019-map-rendering-and-geolocation-dependencies.md), [Domain Model §4](../architecture/domain-model.md#4-bounded-context-slatoki), [Component Library §9.1](../design/component-library.md#91-qibla-compass) |

## Context
FR-SLK-02 requires "a persistently oriented Qibla compass" — the needle must continuously track the real-world bearing to Mecca as the device physically rotates, which needs a live device-heading (magnetometer) reading, not a one-shot value. Flutter has no built-in magnetometer API. Three approaches exist:

1. **`flutter_compass`** — purpose-built package exposing `Stream<CompassEvent>` with `heading` (0–360°, sensor-fused, magnetic-declination-aware on both platforms) and an `accuracy` field for calibration state. Returns a null stream on devices with no magnetometer hardware — a ready-made hook for the wireframe's "magnetometer-unavailable" state.
2. **`sensors_plus`** — raw accelerometer/magnetometer/gyroscope event streams, requiring this codebase to implement its own sensor-fusion (tilt-compensated compass heading) algorithm from raw magnetic-field vectors — real numerical work with real failure modes (device tilt, hard/soft-iron interference) that `flutter_compass` already solves using each platform's native sensor-fusion APIs (`CMDeviceMotion`/`CLLocationManager.heading` on iOS, `SensorManager`'s rotation-vector sensor on Android).
3. **`geolocator`'s heading support** — `geolocator` (already a dependency, ADR-0019) does not expose a continuous compass-heading stream; it is a location package, not a sensor package. Ruled out immediately — no code was written to test this, the package's own API surface confirms it.

## Decision
Use **`flutter_compass` 0.8.1** — resolves cleanly against this project's existing dependency set (confirmed via `flutter pub add --dry-run`), needs no new native permission (magnetometer is a "normal" sensor on both platforms, unlike location), and its `CompassEvent.accuracy` field maps directly onto the wireframe's calibrating/locked states without any custom sensor math.

- `FlutterCompass.events` (a `Stream<CompassEvent>?`) backs a `compassEventStreamProvider`. A `null` stream (device has no magnetometer) maps directly to SCR-009's "magnetometer-unavailable" state — static compass + `errorContainer` banner.
- `QiblaDirectionCalculator` (a pure domain function, no dependency on `flutter_compass` or any Flutter/platform API — see [Domain Model §4](../architecture/domain-model.md#4-bounded-context-slatoki)) computes the great-circle initial bearing from the device's current position to the Kaaba (21.422487°N, 39.826206°E — Masjid al-Haram, Mecca; standard published WGS84 coordinates, not a project-specific assumption).
- The on-screen needle angle is `(qiblaBearing − deviceHeading) mod 360`, computed in the presentation layer by combining the domain calculator's output with the live sensor stream — the calculator itself stays sensor-agnostic and is unit-testable with zero device dependency (same discipline as `clusterPlaces()`/ADR-0020 and `filterPlaces()`/ADR-0021).
- **Calibration threshold**: `accuracy == null` or `accuracy > 15°` is treated as "calibrating" (pulsing needle + hint text); anything at or below that is "locked" (steady needle, no hint). This is a documented, reasonable judgment call — `CompassEvent.accuracy`'s own doc comment states Android values are "hard-coded" per-platform rather than a true measured deviation, so no single "objectively correct" threshold exists; 15° is a commonly-used calibration cutoff in compass-app implementations and is flagged here rather than presented as a spec-derived number.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| `flutter_compass` (chosen) | Purpose-built; native sensor fusion on both platforms; `accuracy` field maps directly to the wireframe's calibrating state; null-stream maps directly to the unavailable state; no new permission | Small package (less battle-tested than `geolocator`/`flutter_map`'s ecosystem footprint); Android `accuracy` semantics are platform-approximate per its own doc comment |
| `sensors_plus` + hand-rolled fusion | More control; already a well-maintained, widely-used package | Would require implementing and testing tilt-compensated compass math ourselves — real numerical/physics work with real edge cases (device tilt, magnetic interference) that a purpose-built package already solves; no `accuracy`-equivalent signal without inventing one |
| `geolocator` heading support | Zero new dependency | Not part of `geolocator`'s API surface — it is a location package; ruled out without needing a prototype |

## Consequences
### Positive
- FR-SLK-02's "persistently oriented" requirement is satisfied by a continuous stream, not a one-shot reading.
- `QiblaDirectionCalculator` has zero dependency on `flutter_compass`, Flutter, or any platform channel — fully unit-testable, matching this project's established pure-domain-function testing discipline.
- The magnetometer-unavailable and calibrating states are both backed by real signals from the package (`null` stream, `accuracy` field), not invented/simulated states.

### Negative / Trade-offs
- The 15° calibration threshold is a judgment call, not a value derived from the approved spec (none exists) — flagged plainly here rather than silently hard-coded with no explanation.
- Verified only on the same physical Android device (`21121119SC`) used throughout this log; iOS's `CLLocationManager`-backed heading behavior is unverified (consistent with every prior ADR's Android-only verification scope in this project).

## Related
- `lib/features/slatoki/domain/services/qibla_direction_calculator.dart`, `lib/features/slatoki/presentation/providers/qibla_providers.dart`, `lib/features/slatoki/presentation/widgets/qibla_compass.dart`, `lib/features/slatoki/presentation/screens/qibla_full_screen.dart`
- `docs/phase-3-implementation-log.md`
