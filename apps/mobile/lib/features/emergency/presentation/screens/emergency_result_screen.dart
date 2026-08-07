import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:permission_handler/permission_handler.dart";

import "../../../../core/router/app_router.dart";
import "../../../../core/theme/color_tokens.dart";
import "../../../../core/theme/shape_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../../map_discovery/domain/entities/location_failure.dart";
import "../../../map_discovery/presentation/screens/navigation_screen.dart";
import "../../domain/entities/emergency_facility_result.dart";
import "../providers/emergency_providers.dart";

/// SCR-011 Emergency Mode Result — **FLAGSHIP** (US-03.1, US-03.2,
/// FR-EMG-01/02). Reached in one tap from bottom nav, no intermediate
/// screen — this screen **is** the destination (replaces
/// `EmergencyPlaceholderScreen` wholesale, per that screen's own doc
/// comment, at the same `AppRoutePaths.emergency` route).
///
/// The primary button opens **in-app navigation only** (`NavigationScreen`
/// — previously external navigation, before this feature) — it does not
/// enter the QR-scan flow. The user navigates there inside the app and
/// manually starts the existing, unchanged QR-scan flow (SCR-013) once at
/// the cabin.
class EmergencyResultScreen extends ConsumerWidget {
  const EmergencyResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<EmergencyFacilityResult?> state = ref.watch(
      emergencyResultProvider,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emergencyResultTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RahatiSpacing.space4),
          child: state.when(
            data: (result) => result == null
                ? _MessageView(
                    icon: Icons.search_off,
                    message: l10n.emergencyNoFacilityFound,
                  )
                : _FacilityResult(result: result),
            loading: () => _LoadingView(message: l10n.emergencyLoadingMessage),
            error: (error, stackTrace) {
              if (error is LocationServiceDisabledFailure) {
                return _MessageView(
                  icon: Icons.location_disabled,
                  message: l10n.emergencyLocationServiceDisabled,
                );
              }
              if (error is LocationPermissionDeniedFailure ||
                  error is LocationPermissionDeniedForeverFailure) {
                return _PermissionDeniedView(l10n: l10n);
              }
              return _MessageView(
                icon: Icons.error_outline,
                message: l10n.emergencyGenericError,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // Same `Semantics(liveRegion: true)` + progress-indicator pattern as
    // `cabin_availability_screen.dart`'s `_StatusView` — content changes
    // asynchronously with no user interaction, so a screen reader must be
    // told when it changes, not only if focused on it.
    return Center(
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: RahatiSpacing.space4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared shape for the no-facility-found (404), location-service-disabled,
/// and generic-error states — all three are a centered icon + message, no
/// action button (unlike the permission-denied state, which gets its own
/// widget for the settings-deep-link button).
class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: RahatiSpacing.space4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

/// Location-permission-denied fallback — message + a settings-deep-link
/// button, per SCR-011's wireframe. Same `openAppSettings()` call as
/// `qr_scanner_screen.dart`'s identical fallback (`permission_handler`,
/// already a dependency).
class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.location_off,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: RahatiSpacing.space4),
                Text(
                  l10n.emergencyLocationPermissionDenied,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RahatiSpacing.space6),
          FilledButton(
            onPressed: openAppSettings,
            child: Text(l10n.emergencyOpenSettingsButton),
          ),
        ],
      ),
    );
  }
}

/// The wireframe's single elevated Card (never a list — exactly one
/// facility per FR-EMG-02) + the large primary Filled Button below it.
class _FacilityResult extends StatelessWidget {
  const _FacilityResult({required this.result});

  final EmergencyFacilityResult result;

  /// Opens in-app navigation (`NavigationScreen`) instead of handing off to
  /// an external maps app — replaces the former `launchExternalNavigation`
  /// call. This screen's own doc comment ("launches external navigation
  /// only") predates this feature; the button still does nothing else
  /// (no QR-scan flow entry) — only *where* "Route" opens changed.
  void _launchNavigation(BuildContext context) {
    final String label = result.place.name.forLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
    context.push<void>(
      AppRoutePaths.navigation,
      extra: NavigationScreenArgs(
        destination: result.place.position,
        destinationLabel: label,
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(1)} km";
    }
    return "${meters.round()} m";
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final RahatiFunctionalColors functionalColors = Theme.of(
      context,
    ).extension<RahatiFunctionalColors>()!;
    final String languageCode = Localizations.localeOf(context).languageCode;

    final String facilityName = result.place.name.forLanguageCode(languageCode);
    final String distanceEtaLine =
        "${_formatDistance(result.place.distanceMeters)} · "
        "${l10n.emergencyEtaOnFoot(result.etaMinutesOnFoot)}";

    // Mirrors `EmergencyPlaceholderScreen`'s own Semantics/ExcludeSemantics
    // wrapping convention — the card's static content is announced as one
    // block; the discount badge's text is included so it's never conveyed
    // by color alone.
    final String cardSemanticsLabel = result.discountEligible
        ? "$facilityName. $distanceEtaLine. ${l10n.emergencyDiscountBadge}"
        : "$facilityName. $distanceEtaLine";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: RahatiShape.mediumRadius),
          child: Padding(
            padding: const EdgeInsets.all(RahatiSpacing.space4),
            child: Semantics(
              label: cardSemanticsLabel,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      facilityName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: RahatiSpacing.space1),
                    Text(
                      distanceEtaLine,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (result.discountEligible) ...<Widget>[
                      const SizedBox(height: RahatiSpacing.space3),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Chip(
                          label: Text(l10n.emergencyDiscountBadge),
                          backgroundColor: functionalColors.successContainer,
                          labelStyle: TextStyle(
                            color: functionalColors.onSuccessContainer,
                          ),
                          side: BorderSide.none,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: RahatiSpacing.space6),
        FilledButton(
          onPressed: () => _launchNavigation(context),
          child: Text(l10n.emergencyResultButton),
        ),
      ],
    );
  }
}
