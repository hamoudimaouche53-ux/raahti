import "package:flutter/material.dart";

import "../../../../core/theme/shape_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/route.dart";

/// The Navigation screen's bottom info card — distance remaining, walking
/// time, and estimated arrival time, per this feature's requirement 3 (Map
/// UI). Purely presentational: [NavigationScreen] decides *when* to show
/// this (only once a [NavigationRoute] exists) and passes the current one
/// in; [isRefreshing] renders a small inline spinner next to the ETA during
/// a background recalculation (distinct from `NavigationScreen`'s own
/// full-screen loading state, shown only for the very first fetch — this
/// card only ever renders once at least one route has resolved).
class RouteInformationCard extends StatelessWidget {
  const RouteInformationCard({
    required this.route,
    required this.isRefreshing,
    super.key,
  });

  final NavigationRoute route;
  final bool isRefreshing;

  String _formatDistance(AppLocalizations l10n, double meters) {
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(1)} km";
    }
    return "${meters.round()} m";
  }

  int _walkingMinutes() => (route.durationSeconds / 60).round();

  String _formatArrival(BuildContext context) {
    final DateTime arrival = DateTime.now().add(
      Duration(seconds: route.durationSeconds.round()),
    );
    return TimeOfDay.fromDateTime(arrival).format(context);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String distanceLine = l10n.navigationDistanceRemaining(
      _formatDistance(l10n, route.distanceMeters),
    );
    final String walkingTimeLine = l10n.navigationWalkingTime(
      _walkingMinutes(),
    );
    final String arrivalLine = l10n.navigationArrivalTime(
      _formatArrival(context),
    );

    // A single Semantics block (liveRegion — this content changes on every
    // recalculation with no user interaction, same discipline as
    // map_screen.dart's `_StatusBanner`/place_detail_sheet.dart's
    // `_DetailStatusLine`) rather than three separate announcements.
    return Semantics(
      liveRegion: true,
      label: "$distanceLine. $walkingTimeLine. $arrivalLine",
      child: ExcludeSemantics(
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: RahatiShape.largeRadius),
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(RahatiSpacing.space4),
            child: Row(
              children: <Widget>[
                Icon(Icons.directions_walk, color: colorScheme.primary),
                const SizedBox(width: RahatiSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(distanceLine, style: textTheme.titleMedium),
                      const SizedBox(height: RahatiSpacing.space1),
                      Text(
                        "$walkingTimeLine · $arrivalLine",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRefreshing) ...<Widget>[
                  const SizedBox(width: RahatiSpacing.space2),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
