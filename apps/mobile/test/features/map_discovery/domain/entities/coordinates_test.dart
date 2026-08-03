import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/coordinates.dart";

void main() {
  group("Coordinates", () {
    test("equality is value-based", () {
      const a = Coordinates(latitude: 36.75, longitude: 3.06);
      const b = Coordinates(latitude: 36.75, longitude: 3.06);
      const c = Coordinates(latitude: 0, longitude: 0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test("asserts latitude is within [-90, 90]", () {
      expect(
        () => Coordinates(latitude: 91, longitude: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test("asserts longitude is within [-180, 180]", () {
      expect(
        () => Coordinates(latitude: 0, longitude: 181),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group("Coordinates.distanceMetersTo", () {
    test("is zero for the same point", () {
      const a = Coordinates(latitude: 36.75, longitude: 3.06);
      expect(a.distanceMetersTo(a), 0);
    });

    test("is symmetric", () {
      const a = Coordinates(latitude: 36.75, longitude: 3.06);
      const b = Coordinates(latitude: 36.80, longitude: 3.10);
      expect(a.distanceMetersTo(b), closeTo(b.distanceMetersTo(a), 0.001));
    });

    test("matches a known reference distance (~1.11km per 0.01° latitude)", () {
      const a = Coordinates(latitude: 36.75, longitude: 3.06);
      const b = Coordinates(latitude: 36.76, longitude: 3.06);
      // 1 degree of latitude is ~111.32km; this is a coarse sanity check,
      // not a geodesy-precision assertion.
      expect(a.distanceMetersTo(b), closeTo(1113, 20));
    });
  });
}
