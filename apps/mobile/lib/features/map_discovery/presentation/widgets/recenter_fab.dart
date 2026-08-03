import "package:flutter/material.dart";

import "../../../../l10n/app_localizations.dart";

/// SCR-003's floating recenter action (US-01.1.6, FR-MAP-06) — M3 FAB per
/// docs/design/component-library.md (`primaryContainer`/`onPrimaryContainer`
/// baseline, reserved for the map "recenter" action). Distinguishes locked
/// (position-tracking active) from unlocked purely by **icon**, not color
/// alone (WCAG 2.2 AA — no information by color/appearance alone), with a
/// distinct M3 role for each so the difference also reads correctly for
/// colorblind users: `primary` (more prominent, "on") when locked,
/// `primaryContainer` (baseline, "off") when unlocked.
class RecenterFab extends StatelessWidget {
  const RecenterFab({
    required this.isLocked,
    required this.onPressed,
    super.key,
  });

  final bool isLocked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String label = isLocked
        ? l10n.mapRecenterLockedTooltip
        : l10n.mapRecenterUnlockedTooltip;

    // An explicit Semantics wrapper (not just FloatingActionButton's
    // `tooltip`, whose semantics contribution is a hint, not a label) —
    // same pattern as PlaceMarker/ClusterMarker.
    return Semantics(
      label: label,
      button: true,
      child: ExcludeSemantics(
        child: FloatingActionButton(
          onPressed: onPressed,
          tooltip: label,
          backgroundColor: isLocked
              ? colorScheme.primary
              : colorScheme.primaryContainer,
          foregroundColor: isLocked
              ? colorScheme.onPrimary
              : colorScheme.onPrimaryContainer,
          child: Icon(isLocked ? Icons.gps_fixed : Icons.gps_not_fixed),
        ),
      ),
    );
  }
}
