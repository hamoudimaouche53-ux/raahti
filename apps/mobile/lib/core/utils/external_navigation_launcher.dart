import "package:flutter/widgets.dart";
import "package:url_launcher/url_launcher.dart";

import "../../l10n/app_localizations.dart";

/// External-navigation launch logic — extracted from
/// `map_discovery/presentation/widgets/place_detail_sheet.dart`'s
/// `_openRoute` (SCR-005/SCR-006's "Directions" button) so the Emergency
/// Mode result screen (SCR-011's "Aller au lieu le plus proche" button)
/// can share the exact same geo:-URI-then-OpenStreetMap-web-fallback
/// behavior instead of duplicating it.
///
/// Tries a `geo:` URI first (opens the device's default maps app, if any),
/// then falls back to the OpenStreetMap web viewer. Returns whether
/// *either* attempt actually launched — this function deliberately shows
/// no SnackBar of its own; each call site keeps full control of its own
/// fallback messaging (`place_detail_sheet.dart`'s existing
/// `placeDetailRouteUnavailable` text and behavior are unchanged by this
/// extraction).
///
/// [context] and [l10n] are accepted but not read internally — kept in the
/// signature for symmetry with both call sites (which already have both
/// in scope) and to leave room for a future shared default message,
/// without forcing a second signature change if that's ever added; today,
/// callers own 100% of the post-launch UI decision, per the paragraph
/// above.
Future<bool> launchExternalNavigation({
  required double lat,
  required double lng,
  required String label,
  required BuildContext context,
  required AppLocalizations l10n,
}) async {
  final Uri geoUri = Uri(
    scheme: "geo",
    host: "$lat,$lng",
    queryParameters: <String, String>{"q": "$lat,$lng($label)"},
  );
  final Uri webFallbackUri = Uri.parse(
    "https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=17/$lat/$lng",
  );

  return await launchUrl(geoUri, mode: LaunchMode.externalApplication) ||
      await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
}
