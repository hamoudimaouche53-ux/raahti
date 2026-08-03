import "package:flutter/material.dart";

import "../../../../l10n/app_localizations.dart";
import "../clustering/map_marker_item.dart";

/// A marker cluster badge (US-01.1.2). Uses M3's `secondaryContainer` /
/// `onSecondaryContainer` roles — generic UI chrome, not a specific
/// place's status, so it deliberately does **not** use a RAH-DOC-002
/// functional color (Foundations §1.3's usage rule: functional colors
/// style only status-carrying elements; a cluster mixes place kinds/pin
/// colors, so it has no single status to represent).
class ClusterMarker extends StatelessWidget {
  const ClusterMarker({required this.cluster, this.onTap, super.key});

  final PlaceClusterItem cluster;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    // Slightly larger for bigger groups, capped so it never overwhelms the
    // map — matches common cluster-badge conventions.
    final double diameter = 32 + (cluster.count.clamp(0, 50) / 50) * 16;

    return Semantics(
      label: l10n.clusterMarkerLabel(cluster.count),
      button: true,
      // Prevents the child Text's own implicit semantics node from
      // merging into (and duplicating/garbling) the explicit label above
      // — the same pattern used by SplashScreen for its loading label.
      child: ExcludeSemantics(
        // GestureDetector wraps a 48×48dp SizedBox, not the (32–48dp,
        // count-dependent) visual badge directly, to meet the project's
        // 48×48dp minimum touch target "regardless of visual size"
        // (docs/design/component-library.md) — found during the US-06.4
        // accessibility audit.
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  "${cluster.count}",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
