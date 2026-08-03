// Traces to: FR-SLK-02, docs/architecture/domain-model.md#4-bounded-context-slatoki.
// Reference bearings independently computed via the same standard
// great-circle initial-bearing formula and cross-checked against
// commonly-published Qibla bearing references for each city (e.g. New
// York's ~58° northeast great-circle bearing is a well-known
// counter-intuitive reference point, not an arbitrary fixture).
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";
import "package:rahati/features/slatoki/domain/services/qibla_direction_calculator.dart";

void main() {
  group("QiblaDirectionCalculator.bearingToMecca", () {
    test("returns a value in [0, 360) for an arbitrary point", () {
      final double bearing = QiblaDirectionCalculator.bearingToMecca(
        const Coordinates(latitude: 36.7538, longitude: 3.0588),
      );
      expect(bearing, greaterThanOrEqualTo(0));
      expect(bearing, lessThan(360));
    });

    test("Algiers → ~105.4° (ESE)", () {
      final double bearing = QiblaDirectionCalculator.bearingToMecca(
        const Coordinates(latitude: 36.7538, longitude: 3.0588),
      );
      expect(bearing, closeTo(105.41, 0.1));
    });

    test("Jakarta → ~295.2° (WNW)", () {
      final double bearing = QiblaDirectionCalculator.bearingToMecca(
        const Coordinates(latitude: -6.2088, longitude: 106.8456),
      );
      expect(bearing, closeTo(295.15, 0.1));
    });

    test("New York → ~58.5° (ENE, the well-known counter-intuitive case)", () {
      final double bearing = QiblaDirectionCalculator.bearingToMecca(
        const Coordinates(latitude: 40.7128, longitude: -74.0060),
      );
      expect(bearing, closeTo(58.48, 0.1));
    });

    test("London → ~119.0° (ESE)", () {
      final double bearing = QiblaDirectionCalculator.bearingToMecca(
        const Coordinates(latitude: 51.5074, longitude: -0.1278),
      );
      expect(bearing, closeTo(118.99, 0.1));
    });

    test("from the Kaaba itself → 0 (degenerate case, no exception)", () {
      final double bearing = QiblaDirectionCalculator.bearingToMecca(
        QiblaDirectionCalculator.kaaba,
      );
      expect(bearing, 0);
    });

    test("kaaba constant matches the published WGS84 Kaaba coordinates", () {
      expect(QiblaDirectionCalculator.kaaba.latitude, closeTo(21.4225, 0.001));
      expect(QiblaDirectionCalculator.kaaba.longitude, closeTo(39.8262, 0.001));
    });
  });
}
