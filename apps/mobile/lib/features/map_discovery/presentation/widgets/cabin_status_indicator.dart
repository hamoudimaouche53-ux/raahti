import "package:flutter/material.dart";

import "../../../../core/theme/color_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/cabin.dart";

/// The bespoke Cabin-Status Indicator — docs/design/component-library.md
/// §9.3: a 24dp circular dot (functional color: `success` = free, `error`
/// = occupied, `outline` = out-of-service) + adjacent `labelMedium` text.
/// The text is **mandatory, never color-only** (WCAG 2.2 AA 1.4.1) —
/// [Semantics] merges the two into one accessible name so a screen reader
/// announces "Libre"/"Occupé"/"Hors service" once, not a bare color name.
///
/// `liveRegion: true` (US-04.5, FR-PAY-05) — this status can now change
/// without user interaction (a Realtime cabin-occupancy update patched
/// into `_StationCabins`'s cabin list), so a screen reader announces the
/// change when it happens, not only when the row is first focused —
/// same "transient state changes are announced" discipline SCR-014's
/// wireframe already established for this app.
class CabinStatusIndicator extends StatelessWidget {
  const CabinStatusIndicator({required this.status, super.key});

  final CabinOccupancyStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final RahatiFunctionalColors functionalColors = Theme.of(
      context,
    ).extension<RahatiFunctionalColors>()!;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final (Color dotColor, String label) = switch (status) {
      CabinOccupancyStatus.free => (
        functionalColors.success,
        l10n.cabinStatusFree,
      ),
      CabinOccupancyStatus.occupied => (
        colorScheme.error,
        l10n.cabinStatusOccupied,
      ),
      CabinOccupancyStatus.outOfService => (
        colorScheme.outline,
        l10n.cabinStatusOutOfService,
      ),
    };

    return Semantics(
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: RahatiSpacing.space2),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
