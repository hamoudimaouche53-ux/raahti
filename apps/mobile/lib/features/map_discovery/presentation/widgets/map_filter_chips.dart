import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/place_filter.dart";
import "../providers/place_filter_provider.dart";

/// SCR-003's horizontal scrollable Filter Chip row (US-01.1.5, FR-MAP-05):
/// the exact multi-select category set the SRS defines (Tout/Gratuit/
/// Payant/RAHETI/Slatoki), plus a single-select distance pair (<1km/<5km)
/// layered onto the already-approved `radiusMeters` API parameter (see
/// ADR-0021). No accessibility (PMR) or open-now chip is included — neither
/// is defined as a *filter* anywhere in the approved specification, only as
/// a place-detail tag (SCR-005/006).
///
/// Reads [placeFilterProvider] directly (a `ConsumerWidget`, not the parent
/// `MapScreen`) so toggling a chip only rebuilds this row, not the map/
/// marker layer above it.
class MapFilterChips extends ConsumerWidget {
  const MapFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlaceFilter filter = ref.watch(placeFilterProvider);
    final PlaceFilterNotifier notifier = ref.read(placeFilterProvider.notifier);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          FilterChip(
            label: Text(l10n.mapFilterAll),
            selected: filter.categories.isEmpty,
            onSelected: (_) => notifier.clearAll(),
          ),
          const SizedBox(width: RahatiSpacing.space2),
          _categoryChip(
            l10n.mapFilterFree,
            PlaceCategory.free,
            filter,
            notifier,
          ),
          const SizedBox(width: RahatiSpacing.space2),
          _categoryChip(
            l10n.mapFilterPaid,
            PlaceCategory.paid,
            filter,
            notifier,
          ),
          const SizedBox(width: RahatiSpacing.space2),
          _categoryChip(
            l10n.mapFilterRahatiUnit,
            PlaceCategory.rahatiUnit,
            filter,
            notifier,
          ),
          const SizedBox(width: RahatiSpacing.space2),
          _categoryChip(
            l10n.mapFilterSlatoki,
            PlaceCategory.slatoki,
            filter,
            notifier,
          ),
          const SizedBox(width: RahatiSpacing.space4),
          _distanceChip(
            l10n.mapFilterUnder1km,
            DistanceFilter.under1km,
            filter,
            notifier,
          ),
          const SizedBox(width: RahatiSpacing.space2),
          _distanceChip(
            l10n.mapFilterUnder5km,
            DistanceFilter.under5km,
            filter,
            notifier,
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(
    String label,
    PlaceCategory category,
    PlaceFilter filter,
    PlaceFilterNotifier notifier,
  ) {
    return FilterChip(
      label: Text(label),
      selected: filter.categories.contains(category),
      onSelected: (_) => notifier.toggleCategory(category),
    );
  }

  Widget _distanceChip(
    String label,
    DistanceFilter distance,
    PlaceFilter filter,
    PlaceFilterNotifier notifier,
  ) {
    final bool selected = filter.distance == distance;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) =>
          notifier.setDistance(selected ? DistanceFilter.any : distance),
    );
  }
}
