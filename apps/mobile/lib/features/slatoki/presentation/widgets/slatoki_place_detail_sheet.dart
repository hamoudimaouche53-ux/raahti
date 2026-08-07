import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../core/router/app_router.dart";
import "../../../../core/theme/shape_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../../map_discovery/domain/entities/place.dart";
import "../../../map_discovery/presentation/screens/navigation_screen.dart";
import "../../domain/entities/slatoki_place.dart";
import "slatoki_tent_status_section.dart";
import "women_verification_section.dart";

/// SCR-010 — Slatoki Place Detail (US-02.1.4/02.1.5, FR-SLK-04/05), opened
/// as a modal bottom sheet on a [SlatokiPlaceListItem] tap. Same Bottom
/// Sheet base as SCR-005/SCR-006 (`PlaceDetailSheet`, map_discovery) —
/// drag handle, header, tag chips, distance, "Itinéraire" — with
/// [WomenVerificationSection] placed directly under the header, per the
/// wireframe. For RAHETI-tent places (`placeKind == station`), the full
/// [SlatokiTentStatusSection] is embedded inline where a generic
/// Cabin-Status Indicator would otherwise go, per SCR-010's explicit
/// wording.
class SlatokiPlaceDetailSheet extends StatelessWidget {
  const SlatokiPlaceDetailSheet({required this.slatokiPlace, super.key});

  final SlatokiPlace slatokiPlace;

  Place get _place => slatokiPlace.place;

  /// Opens in-app navigation (`NavigationScreen`) instead of handing off to
  /// an external maps app — replaces this sheet's former inline
  /// geo:-URI-then-OpenStreetMap-web-fallback logic (the same behavior
  /// `core/utils/external_navigation_launcher.dart` centralized for
  /// `PlaceDetailSheet`/Emergency Mode, but this sheet had its own
  /// un-deduplicated copy).
  void _openRoute(BuildContext context) {
    context.push<void>(
      AppRoutePaths.navigation,
      extra: NavigationScreenArgs(
        destination: _place.position,
        destinationLabel: _place.name.forLanguageCode(
          Localizations.localeOf(context).languageCode,
        ),
      ),
    );
  }

  String _tagLabel(AppLocalizations l10n, String tag) {
    return switch (tag) {
      "women_confirmed" => l10n.tagWomenConfirmed,
      "wudu" => l10n.tagWudu,
      "pmr" => l10n.tagPmr,
      "prayer" => l10n.tagPrayer,
      "open_now" => l10n.tagOpenNow,
      _ => tag,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String languageCode = Localizations.localeOf(context).languageCode;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(RahatiShape.extraLarge),
              topRight: Radius.circular(RahatiShape.extraLarge),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: RahatiSpacing.space4,
              vertical: RahatiSpacing.space2,
            ),
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: RahatiSpacing.space3),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: RahatiShape.fullRadius,
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _place.name.forLanguageCode(languageCode),
                      style: textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.placeDetailClose,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: RahatiSpacing.space2),
              WomenVerificationSection(
                level: slatokiPlace.womenVerificationLevel,
              ),
              const SizedBox(height: RahatiSpacing.space3),
              Row(
                children: <Widget>[
                  Icon(
                    _place.averageRating != null
                        ? Icons.star
                        : Icons.star_border,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: RahatiSpacing.space1),
                  Text(
                    _place.averageRating != null
                        ? _place.averageRating!.toStringAsFixed(1)
                        : l10n.placeDetailNoReviews,
                    style: textTheme.bodyMedium,
                  ),
                  if (_place.averageRating != null) ...<Widget>[
                    const SizedBox(width: RahatiSpacing.space1),
                    Text(
                      "(${l10n.placeDetailReviewCount(_place.reviewCount)})",
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (_place.tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: RahatiSpacing.space3),
                Wrap(
                  spacing: RahatiSpacing.space2,
                  runSpacing: RahatiSpacing.space2,
                  children: <Widget>[
                    for (final String tag in _place.tags)
                      Chip(
                        label: Text(_tagLabel(l10n, tag)),
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                  ],
                ),
              ],
              if (_place.placeKind == PlaceKind.station) ...<Widget>[
                const SizedBox(height: RahatiSpacing.space3),
                // No extra horizontal padding here — SlatokiTentStatusCard
                // already carries its own Card margin, on top of this
                // ListView's own; a slightly wider inset than the sheet's
                // other rows, accepted as a minor, harmless side effect of
                // reusing the same card in both the list and this sheet.
                SlatokiTentStatusSection(
                  placeId: _place.id,
                  placeName: _place.name.forLanguageCode(languageCode),
                ),
              ],
              const SizedBox(height: RahatiSpacing.space3),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.social_distance,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: RahatiSpacing.space2),
                  Text(
                    _formatDistance(_place.distanceMeters),
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: RahatiSpacing.space4),
              // Outlined, per SCR-010's component list ("Buttons (Outlined
              // 'Itinéraire')") — deliberately distinct from
              // PlaceDetailSheet's FilledButton, matching the wireframe.
              OutlinedButton.icon(
                onPressed: () => _openRoute(context),
                icon: const Icon(Icons.directions),
                label: Text(l10n.placeDetailRoute),
              ),
              const SizedBox(height: RahatiSpacing.space4),
            ],
          ),
        );
      },
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(1)} km";
    }
    return "${meters.round()} m";
  }
}
