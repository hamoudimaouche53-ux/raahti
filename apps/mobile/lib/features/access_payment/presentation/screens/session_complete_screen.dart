import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../core/router/app_router.dart";
import "../../../../core/theme/color_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../../map_discovery/domain/entities/place.dart" show PlaceKind;
import "../../../map_discovery/presentation/screens/submit_review_screen.dart";
import "../../domain/entities/money.dart";

/// `state.extra` payload for [AppRoutePaths.sessionComplete] — a small
/// typed carrier beats an untyped `Map` cast, same precedent as
/// `PaymentProcessingArgs`/`UnlockConfirmationArgs`.
class SessionCompleteArgs {
  const SessionCompleteArgs({
    required this.amount,
    required this.duration,
    required this.placeId,
    required this.placeName,
  });

  /// `null` for a free-cabin session — the ERD's own `TRANSACTION` table
  /// doc comment states "a free-access session produces no transaction
  /// row," so there's genuinely no amount to show, not a zero one.
  final Money? amount;
  final Duration duration;

  /// Feeds "Laisser un avis" → SCR-007 (`SubmitReviewArgs`).
  final String placeId;
  final String placeName;
}

/// SCR-019 — Session Complete / Exit Confirmation (US-04.6, FR-PAY-06).
///
/// Reached identically whether the session ended via the real (or mock)
/// door-sensor-close broadcast or the manual "J'ai terminé" action on
/// SCR-017 — "visually identical either way," per the wireframe. This
/// screen itself doesn't know or care which path got it here; that
/// distinction lives entirely in `UnlockConfirmationScreen`.
///
/// "Laisser un avis" routes to SCR-007 (Submit Review, US-05.2,
/// Feature 20) — every place reachable through this screen is a station
/// (see `SessionCompleteArgs`'s own doc comment), so `PlaceKind.station`
/// is passed directly rather than threaded all the way from
/// `PlaceDetailSheet`.
class SessionCompleteScreen extends StatelessWidget {
  const SessionCompleteScreen({
    required this.amount,
    required this.duration,
    required this.placeId,
    required this.placeName,
    super.key,
  });

  final Money? amount;
  final Duration duration;
  final String placeId;
  final String placeName;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RahatiFunctionalColors functionalColors = Theme.of(
      context,
    ).extension<RahatiFunctionalColors>()!;
    final Money? amountValue = amount;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(RahatiSpacing.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.check_circle,
                  size: 72,
                  color: functionalColors.success,
                ),
                const SizedBox(height: RahatiSpacing.space4),
                Text(
                  l10n.sessionCompleteHeadline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: RahatiSpacing.space6),
                _SummaryRow(
                  label: l10n.sessionCompleteAmountLabel,
                  value: amountValue == null
                      ? l10n.sessionCompleteAmountFree
                      : "${amountValue.amount} ${amountValue.currency}",
                ),
                const SizedBox(height: RahatiSpacing.space2),
                _SummaryRow(
                  label: l10n.sessionCompleteDurationLabel,
                  value: l10n.sessionCompleteDurationMinutes(
                    duration.inMinutes,
                  ),
                ),
                const SizedBox(height: RahatiSpacing.space8),
                FilledButton(
                  onPressed: () => context.push<void>(
                    AppRoutePaths.submitReview,
                    extra: SubmitReviewArgs(
                      placeKind: PlaceKind.station,
                      placeId: placeId,
                      placeName: placeName,
                    ),
                  ),
                  child: Text(l10n.sessionCompleteReviewButton),
                ),
                const SizedBox(height: RahatiSpacing.space2),
                TextButton(
                  onPressed: () => context.go(AppRoutePaths.map),
                  child: Text(l10n.cabinAvailabilityBackToMapButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single transaction-summary row — the wireframe's own accessibility
/// requirement ("summary values are read in full, not abbreviated") is
/// satisfied by the label/value strings themselves already being
/// full-word text (`sessionCompleteDurationMinutes` never abbreviates
/// "minutes"), not by any extra `Semantics` wrapping here.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          "$label : ",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
