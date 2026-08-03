import "package:flutter/material.dart";

import "../../../../core/theme/color_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../../map_discovery/domain/entities/place.dart";
import "../../domain/entities/slatoki_place.dart";
import "../../domain/entities/women_verification_level.dart";
import "slatoki_tent_status_section.dart";

/// A row for a filtered [SlatokiPlace] on SCR-008.
///
/// - RAHETI-tent places (`placeKind == station`, US-02.1.5, FR-SLK-05):
///   the full [SlatokiTentStatusSection] (deployment status, mat capacity,
///   amenities) — the wireframe's own "▣ Tente RAHETI — Déployée / 4 tapis
///   · 💡 · 🚪" row.
/// - Everything else (US-02.1.4): a minimal two-line row — bilingual name,
///   distance, and a "Femmes ✓" badge for verified mosques (reusing
///   EPIC-01's existing `tagWomenConfirmed` label, not a duplicate string).
class SlatokiPlaceListItem extends StatelessWidget {
  const SlatokiPlaceListItem({
    required this.slatokiPlace,
    super.key,
    this.onTap,
  });

  final SlatokiPlace slatokiPlace;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;
    final String name = slatokiPlace.place.name.forLanguageCode(languageCode);

    if (slatokiPlace.place.placeKind == PlaceKind.station) {
      return SlatokiTentStatusSection(
        placeId: slatokiPlace.place.id,
        placeName: name,
        onTap: onTap,
      );
    }

    final AppLocalizations l10n = AppLocalizations.of(context);
    final String distance = _formatDistance(slatokiPlace.place.distanceMeters);
    final bool isVerified =
        slatokiPlace.womenVerificationLevel ==
        WomenVerificationLevel.verifiedConfirmed;

    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.mosque_outlined),
      title: Text(name),
      subtitle: Text(distance),
      trailing: isVerified
          ? Text(
              l10n.tagWomenConfirmed,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(
                  context,
                ).extension<RahatiFunctionalColors>()!.slatoki,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(1)} km";
    }
    return "${meters.round()} m";
  }
}
