// Traces to: US-01.1.4, US-01.1.5 (FR-MAP-04, FR-MAP-05).
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/map_discovery/domain/entities/place_filter.dart";
import "package:rahati/features/map_discovery/presentation/providers/place_filter_provider.dart";

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test("starts with the default (inactive) filter", () {
    expect(container.read(placeFilterProvider), const PlaceFilter());
  });

  test("setSearchQuery updates the search query", () {
    container.read(placeFilterProvider.notifier).setSearchQuery("wc");
    expect(container.read(placeFilterProvider).searchQuery, "wc");
  });

  test("toggleCategory adds then removes a category", () {
    final notifier = container.read(placeFilterProvider.notifier);

    notifier.toggleCategory(PlaceCategory.free);
    expect(container.read(placeFilterProvider).categories, {
      PlaceCategory.free,
    });

    notifier.toggleCategory(PlaceCategory.free);
    expect(container.read(placeFilterProvider).categories, isEmpty);
  });

  test("toggleCategory supports multiple simultaneous selections", () {
    final notifier = container.read(placeFilterProvider.notifier);

    notifier.toggleCategory(PlaceCategory.free);
    notifier.toggleCategory(PlaceCategory.slatoki);

    expect(container.read(placeFilterProvider).categories, {
      PlaceCategory.free,
      PlaceCategory.slatoki,
    });
  });

  test("setDistance updates the distance cap", () {
    container
        .read(placeFilterProvider.notifier)
        .setDistance(DistanceFilter.under1km);
    expect(
      container.read(placeFilterProvider).distance,
      DistanceFilter.under1km,
    );
  });

  test("clearAll resets to the default filter", () {
    final notifier = container.read(placeFilterProvider.notifier);
    notifier
      ..setSearchQuery("wc")
      ..toggleCategory(PlaceCategory.free)
      ..setDistance(DistanceFilter.under1km);

    notifier.clearAll();

    expect(container.read(placeFilterProvider), const PlaceFilter());
  });

  test("setSearchQuery with the same value does not emit a new state", () {
    final notifier = container.read(placeFilterProvider.notifier);
    notifier.setSearchQuery("wc");

    var notified = false;
    container.listen(
      placeFilterProvider,
      (previous, next) => notified = true,
      fireImmediately: false,
    );
    notifier.setSearchQuery("wc");

    expect(notified, isFalse);
  });
}
