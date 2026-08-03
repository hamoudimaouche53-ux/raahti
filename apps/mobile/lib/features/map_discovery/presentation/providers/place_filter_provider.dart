import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../domain/entities/place_filter.dart";

/// Holds the active [PlaceFilter] for `MapScreen` (US-01.1.4/US-01.1.5).
///
/// The search bar widget is responsible for debouncing keystrokes before
/// calling [setSearchQuery] — every value that reaches this Notifier is
/// applied immediately, so `MapScreen` never rebuilds more often than the
/// user's settled input actually changes.
class PlaceFilterNotifier extends Notifier<PlaceFilter> {
  @override
  PlaceFilter build() => const PlaceFilter();

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
  }

  void toggleCategory(PlaceCategory category) {
    final Set<PlaceCategory> next = Set<PlaceCategory>.of(state.categories);
    if (!next.remove(category)) next.add(category);
    state = state.copyWith(categories: next);
  }

  void setDistance(DistanceFilter distance) {
    if (state.distance == distance) return;
    state = state.copyWith(distance: distance);
  }

  void clearAll() => state = const PlaceFilter();
}

final NotifierProvider<PlaceFilterNotifier, PlaceFilter> placeFilterProvider =
    NotifierProvider<PlaceFilterNotifier, PlaceFilter>(PlaceFilterNotifier.new);
