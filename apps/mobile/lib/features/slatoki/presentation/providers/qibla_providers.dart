import "package:flutter_compass/flutter_compass.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../map_discovery/domain/entities/coordinates.dart";
import "../../../map_discovery/presentation/providers/place_providers.dart";
import "../../domain/services/qibla_direction_calculator.dart";

/// Raw `flutter_compass` access, wrapped behind an overridable [Provider]
/// (ADR-0025) — the same DI pattern `place_providers.dart` uses for device
/// sensors, so widget tests can inject a fake stream (or `null`, simulating
/// a device with no magnetometer) instead of touching a real platform
/// channel.
final Provider<Stream<CompassEvent>?> rawCompassEventsProvider =
    Provider<Stream<CompassEvent>?>((ref) => FlutterCompass.events);

/// `false` only when the device genuinely has no magnetometer
/// (`FlutterCompass.events == null`) — SCR-009's "magnetometer-unavailable"
/// state (Component Library §9.1).
final Provider<bool> compassAvailableProvider = Provider<bool>(
  (ref) => ref.watch(rawCompassEventsProvider) != null,
);

/// Live device heading. An empty stream (never emits) when unavailable —
/// [compassAvailableProvider] is what UI checks to distinguish "still
/// waiting for the first reading" from "will never have a reading".
final StreamProvider<CompassEvent> compassEventProvider =
    StreamProvider<CompassEvent>((ref) {
      return ref.watch(rawCompassEventsProvider) ??
          const Stream<CompassEvent>.empty();
    });

/// The bearing to Mecca from the device's current position — derived from
/// [userPositionStreamProvider] (map_discovery, US-01.1.6) rather than
/// starting a second GPS stream; Slatoki has no reason to track position
/// independently, and FR-SLK-02 doesn't ask for it.
final Provider<AsyncValue<double>> qiblaBearingProvider =
    Provider<AsyncValue<double>>((ref) {
      final AsyncValue<Coordinates> position = ref.watch(
        userPositionStreamProvider,
      );
      return position.whenData(QiblaDirectionCalculator.bearingToMecca);
    });
