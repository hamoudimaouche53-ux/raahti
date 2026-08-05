import "package:flutter/material.dart";

import "../../../../l10n/app_localizations.dart";

/// The user's own live position, per FR-MAP-01. Uses M3's `primary` role
/// (this is app chrome, not a place-status pin — never a functional color).
class UserPositionMarker extends StatelessWidget {
  const UserPositionMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // Previously a hard-coded French literal with no l10n import at all —
    // a screen reader would announce/mispronounce French regardless of
    // the app's actual locale (WCAG 3.1.2, US-06.4 finding F21).
    return Semantics(
      label: AppLocalizations.of(context).mapUserPositionMarkerLabel,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.surface, width: 3),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Colors.black38, blurRadius: 4),
          ],
        ),
      ),
    );
  }
}
