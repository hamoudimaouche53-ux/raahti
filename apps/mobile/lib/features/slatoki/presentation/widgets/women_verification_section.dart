import "package:flutter/material.dart";

import "../../../../core/theme/color_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/women_verification_level.dart";

/// SCR-010 (US-02.1.4, FR-SLK-04) — placed directly under the sheet's
/// header, not buried in the generic tag row: a prominent filled `slatoki`
/// chip when confirmed, or a neutral (not alarming) note otherwise, per
/// the wireframe's explicit tone guidance ("informational, not alarming").
/// The verification's meaning is conveyed in text either way — never by
/// the `slatoki` color alone (WCAG 2.2 AA, same rule Component Library
/// §9.3 states for `CabinStatusIndicator`).
class WomenVerificationSection extends StatelessWidget {
  const WomenVerificationSection({required this.level, super.key});

  final WomenVerificationLevel level;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (level == WomenVerificationLevel.verifiedConfirmed) {
      final RahatiFunctionalColors functionalColors = Theme.of(
        context,
      ).extension<RahatiFunctionalColors>()!;
      return Chip(
        avatar: Icon(
          Icons.verified,
          size: 18,
          color: functionalColors.onSlatoki,
        ),
        label: Text(l10n.slatokiWomenVerifiedChipLabel),
        backgroundColor: functionalColors.slatoki,
        labelStyle: TextStyle(color: functionalColors.onSlatoki),
        side: BorderSide.none,
      );
    }

    return Text(
      l10n.slatokiWomenGenericNote,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }
}
