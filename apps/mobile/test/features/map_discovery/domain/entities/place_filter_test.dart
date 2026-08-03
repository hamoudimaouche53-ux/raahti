// Traces to: US-01.1.4, US-01.1.5 (FR-MAP-04, FR-MAP-05).
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/place_filter.dart";

void main() {
  group("PlaceFilter", () {
    test("the default filter is inactive", () {
      expect(const PlaceFilter().isActive, isFalse);
    });

    test("a non-empty search query makes the filter active", () {
      expect(const PlaceFilter(searchQuery: "wc").isActive, isTrue);
    });

    test("a whitespace-only search query does not make the filter active", () {
      expect(const PlaceFilter(searchQuery: "   ").isActive, isFalse);
    });

    test("a selected category makes the filter active", () {
      expect(
        const PlaceFilter(categories: {PlaceCategory.free}).isActive,
        isTrue,
      );
    });

    test("a distance cap other than 'any' makes the filter active", () {
      expect(
        const PlaceFilter(distance: DistanceFilter.under1km).isActive,
        isTrue,
      );
    });

    test("copyWith overrides only the given fields", () {
      const base = PlaceFilter(
        searchQuery: "wc",
        categories: {PlaceCategory.free},
        distance: DistanceFilter.under1km,
      );
      final updated = base.copyWith(searchQuery: "slatoki");

      expect(updated.searchQuery, "slatoki");
      expect(updated.categories, {PlaceCategory.free});
      expect(updated.distance, DistanceFilter.under1km);
    });

    test(
      "two filters with the same fields (categories in any order) are equal",
      () {
        const a = PlaceFilter(
          categories: {PlaceCategory.free, PlaceCategory.slatoki},
        );
        const b = PlaceFilter(
          categories: {PlaceCategory.slatoki, PlaceCategory.free},
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      },
    );

    test("filters differing only by category set are not equal", () {
      const a = PlaceFilter(categories: {PlaceCategory.free});
      const b = PlaceFilter(categories: {PlaceCategory.paid});
      expect(a, isNot(b));
    });
  });

  group("DistanceFilter", () {
    test("any has no distance cap", () {
      expect(DistanceFilter.any.maxMeters, isNull);
    });

    test("under1km and under5km carry their meter caps", () {
      expect(DistanceFilter.under1km.maxMeters, 1000);
      expect(DistanceFilter.under5km.maxMeters, 5000);
    });
  });
}
