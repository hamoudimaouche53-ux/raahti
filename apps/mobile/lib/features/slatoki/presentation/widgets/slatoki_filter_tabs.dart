import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/prayer_facility_filter.dart";
import "../providers/slatoki_place_providers.dart";

/// SCR-008's filter tab row (FR-SLK-03) — M3 Primary Tabs per
/// docs/design/component-library.md §5, not Chips: exactly one of the 3
/// modes is always selected, no "all" state.
class SlatokiFilterTabs extends ConsumerStatefulWidget {
  const SlatokiFilterTabs({super.key});

  @override
  ConsumerState<SlatokiFilterTabs> createState() => _SlatokiFilterTabsState();
}

class _SlatokiFilterTabsState extends ConsumerState<SlatokiFilterTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: PrayerFacilityFilter.values.length,
    vsync: this,
    initialIndex: ref.read(prayerFacilityFilterProvider).index,
  )..addListener(_onTabChanged);

  void _onTabChanged() {
    if (_controller.indexIsChanging) return;
    ref
        .read(prayerFacilityFilterProvider.notifier)
        .set(PrayerFacilityFilter.values[_controller.index]);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // Keeps the tab bar in sync if the filter is ever changed from
    // elsewhere (not exercised by this story, but correct by construction
    // rather than assuming this widget is the only writer).
    final int activeIndex = ref.watch(prayerFacilityFilterProvider).index;
    if (_controller.index != activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.animateTo(activeIndex);
      });
    }

    return TabBar(
      controller: _controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: <Widget>[
        Tab(text: l10n.slatokiFilterPrayerOnly),
        Tab(text: l10n.slatokiFilterWuduOnly),
        Tab(text: l10n.slatokiFilterPrayerAndWudu),
      ],
    );
  }
}
