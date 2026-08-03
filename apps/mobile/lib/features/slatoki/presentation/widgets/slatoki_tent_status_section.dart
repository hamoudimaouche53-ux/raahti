import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../l10n/app_localizations.dart";
import "../../../map_discovery/domain/entities/station_detail.dart";
import "../../../map_discovery/presentation/providers/place_detail_providers.dart";
import "slatoki_tent_status_card.dart";

/// Lazily fetches [StationDetail] via the **existing**
/// `stationDetailProvider` (map_discovery, US-01.2.2/02.3) — reused as-is,
/// not duplicated — and renders [SlatokiTentStatusCard] once
/// `slatokiTent` resolves. Used by both [SlatokiPlaceListItem] (SCR-008,
/// for RAHETI-tent places) and `SlatokiPlaceDetailSheet` (SCR-010's
/// "embedded inline instead of a generic Cabin-Status Indicator").
///
/// **Known trade-off, stated plainly**: rendering this per list item means
/// one `GET /stations/{id}` per RAHETI-tent place shown — acceptable for
/// the small number of Slatoki-qualified places typically nearby, but a
/// real N+1 pattern if `/slatoki/places` ever returns many tents at once.
/// Not fixed here: extending `SlatokiPlaceSummary` to carry tent fields
/// directly would be an unrequested API contract change, not something
/// this story asks for.
class SlatokiTentStatusSection extends ConsumerWidget {
  const SlatokiTentStatusSection({
    required this.placeId,
    required this.placeName,
    super.key,
    this.onTap,
  });

  final String placeId;
  final String placeName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<StationDetail> detail = ref.watch(
      stationDetailProvider(placeId),
    );

    return detail.when(
      data: (stationDetail) {
        final tent = stationDetail.slatokiTent;
        if (tent == null) {
          // Defensive fallback, not expected in practice: every
          // station-kind place `/slatoki/places` returns is, by
          // definition, Slatoki-qualified.
          return ListTile(onTap: onTap, title: Text(placeName));
        }
        return SlatokiTentStatusCard(
          placeName: placeName,
          tent: tent,
          onTap: onTap,
        );
      },
      loading: () => ListTile(
        title: Text(placeName),
        subtitle: Text(l10n.placeDetailDetailLoading),
      ),
      error: (error, stackTrace) => ListTile(
        title: Text(placeName),
        subtitle: Text(l10n.placeDetailDetailError),
        leading: const Icon(Icons.error_outline),
      ),
    );
  }
}
