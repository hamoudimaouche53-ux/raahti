import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:url_launcher/url_launcher.dart";

import "../../../../core/constants/env.dart";
import "../../../../core/router/app_router.dart";
import "../../../../core/theme/shape_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../../access_payment/domain/entities/access_session.dart";
import "../../../access_payment/domain/entities/access_session_status.dart";
import "../../../access_payment/domain/entities/money.dart" as access_payment;
import "../../../access_payment/presentation/screens/payment_method_selection_sheet.dart";
import "../../../access_payment/presentation/screens/payment_processing_screen.dart";
import "../../../access_payment/presentation/screens/unlock_confirmation_screen.dart";
import "../../domain/entities/cabin.dart";
import "../../domain/entities/cabin_occupancy_update.dart";
import "../../domain/entities/money.dart";
import "../../domain/entities/place.dart";
import "../../domain/entities/station_detail.dart";
import "../../domain/entities/third_party_place_detail.dart";
import "../providers/place_detail_providers.dart";
import "cabin_status_indicator.dart";

/// SCR-005/SCR-006 — Place Detail Sheet (US-01.1.3, US-01.2.1…05,
/// FR-PLC-01…05), opened as a modal bottom sheet on marker tap.
///
/// Two data sources feed this sheet:
/// - The [place] summary (already fetched by `MapScreen`'s nearby-places
///   query) — name, rating, tags, free/paid, distance — rendered
///   immediately, no network wait.
/// - The **full detail** — [StationDetail] (cabins, real-time occupancy,
///   tariff) or [ThirdPartyPlaceDetail] (declarative open/closed status)
///   — fetched lazily via [stationDetailProvider]/[thirdPartyPlaceDetailProvider]
///   once the sheet opens (US-01.2.2/US-01.2.3), rendered by
///   [_PlaceDetailExtra] below the summary once it resolves.
///
/// "Scanner le QR" (US-04.1/04.2/04.3) routes to SCR-013 (`QrScannerScreen`)
/// then orchestrates SCR-015/016/018 (US-04.3) from here. This feature now
/// **does** import `access_payment`'s domain entities (`AccessSession`,
/// `AccessSessionStatus`) — a deliberate change from US-04.1's original
/// "typeless result" decoupling, since branching free-vs-paid requires
/// reading `AccessSession.status`, and pricing a paid cabin requires
/// cross-referencing [Cabin.price] against `AccessSession.cabinId`. The
/// established one-directional dependency (`access_payment` reads from
/// `map_discovery`, never the reverse) is unaffected — this is still
/// `map_discovery` reading `access_payment`, the already-allowed
/// direction, just no longer avoided where it's actually needed.
class PlaceDetailSheet extends ConsumerWidget {
  const PlaceDetailSheet({required this.place, super.key});

  final Place place;

  /// SCR-013 → SCR-014 (already resolved by the time this returns) →
  /// branches per `AccessSession.status`: `unlocked` means a free
  /// cabin already got direct access from `POST /access-sessions` alone
  /// (`AccessSessionRepository`'s own doc comment) — SCR-015/016 are
  /// skipped entirely, straight to SCR-017 (US-04.4), per the approved
  /// user flow. Any other status (`initiated`) means a paid cabin —
  /// proceeds to [_payAndUnlock].
  Future<void> _scanQr(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final AccessSession? session = await context.push<AccessSession>(
      AppRoutePaths.accessPaymentScan,
    );
    if (session == null || !context.mounted) return;

    final List<Cabin> cabins =
        ref.read(stationDetailProvider(place.id)).value?.cabins ??
        const <Cabin>[];
    final Cabin? cabin = cabins
        .where((c) => c.id == session.cabinId)
        .firstOrNull;
    // Falls back to the raw id if the lookup somehow misses — shouldn't
    // happen (the scanned cabin belongs to this station by construction),
    // but a visible fallback beats a crash on SCR-017's display line.
    final String cabinCode = cabin?.code ?? session.cabinId;

    if (session.status == AccessSessionStatus.unlocked) {
      // Free cabin — no Transaction/amount exists (ERD §"TRANSACTION"'s
      // own doc comment).
      await _showUnlockConfirmation(
        context,
        ref,
        accessSessionId: session.id,
        cabinId: session.cabinId,
        cabinCode: cabinCode,
        unlockedAt: session.unlockedAt ?? session.startedAt,
        amount: null,
      );
      return;
    }

    // A missing/priceless lookup shouldn't be possible for a paid cabin
    // (the button that reaches here only shows once `stationDetailProvider`
    // has resolved) — `0 DZD` is a safe, visible fallback rather than a
    // crash if the scanned cabin somehow isn't in this station's list.
    // `access_payment`'s own `Money` (aliased above) is Access & Payment's
    // value object, deliberately not the same class as this one — see
    // `access_payment.Money`'s doc comment — so the conversion below is a
    // real type boundary, not a redundant wrap.
    final Money? price = cabin?.price;
    final access_payment.Money amount = price == null
        ? const access_payment.Money(amount: "0", currency: "DZD")
        : access_payment.Money(amount: price.amount, currency: price.currency);

    await _payAndUnlock(
      context,
      ref,
      session.id,
      session.cabinId,
      cabinCode,
      amount,
    );
  }

  /// SCR-015 (Modal Bottom Sheet, shown directly — not a route, per its
  /// wireframe) → SCR-016/018 (`PaymentProcessingScreen`, a route). Loops
  /// on [PaymentRetrySignal.retryMethodSelection] (SCR-018's
  /// payment-declined "Réessayer") to re-show SCR-015 with the same
  /// [AccessSession] — the unlock-failed-refunded variant's "Réessayer"
  /// and both variants' "Retour à la carte" are handled entirely inside
  /// `PaymentProcessingScreen` via `context.go`, so they never reach this
  /// loop (the pushed route's Future is simply abandoned).
  Future<void> _payAndUnlock(
    BuildContext context,
    WidgetRef ref,
    String accessSessionId,
    String cabinId,
    String cabinCode,
    access_payment.Money amount,
  ) async {
    while (true) {
      if (!context.mounted) return;
      final String? paymentMethodId = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (context) => PaymentMethodSelectionSheet(amount: amount),
      );
      if (paymentMethodId == null || !context.mounted) return;

      final Object? outcome = await context.push<Object>(
        AppRoutePaths.accessPaymentProcessing,
        extra: PaymentProcessingArgs(
          accessSessionId: accessSessionId,
          paymentMethodId: paymentMethodId,
        ),
      );

      if (outcome is AccessSession) {
        if (!context.mounted) return;
        await _showUnlockConfirmation(
          context,
          ref,
          accessSessionId: outcome.id,
          cabinId: cabinId,
          cabinCode: cabinCode,
          unlockedAt: outcome.unlockedAt ?? outcome.startedAt,
          amount: amount,
        );
        return;
      }
      if (outcome != PaymentRetrySignal.retryMethodSelection) return;
      // else: loop — re-show SCR-015.
    }
  }

  /// SCR-017 (US-04.4) — pushed once a cabin is confirmed `unlocked`,
  /// replacing the temporary success SnackBar Feature 6/13 used as a
  /// stopgap while SCR-017 didn't exist yet. [cabinId] feeds
  /// [_cabinFreedStream] (US-04.6, FR-PAY-06) — a plain `Stream<void>`
  /// handed to `UnlockConfirmationScreen`, which never imports
  /// `map_discovery` itself (see that screen's own doc comment).
  Future<void> _showUnlockConfirmation(
    BuildContext context,
    WidgetRef ref, {
    required String accessSessionId,
    required String cabinId,
    required String cabinCode,
    required DateTime unlockedAt,
    required access_payment.Money? amount,
  }) async {
    if (!context.mounted) return;
    final String stationName = place.name.forLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
    await context.push<void>(
      AppRoutePaths.accessPaymentUnlock,
      extra: UnlockConfirmationArgs(
        accessSessionId: accessSessionId,
        cabinCode: cabinCode,
        stationName: stationName,
        startedAt: unlockedAt,
        amount: amount,
        cabinFreedStream: _cabinFreedStream(ref, cabinId),
        placeId: place.id,
        placeName: stationName,
      ),
    );
  }

  /// A second, independent subscription to the same
  /// `station:{stationId}:cabins` Realtime channel `_StationCabins`
  /// already watches via `cabinOccupancyUpdatesProvider` (US-04.5) —
  /// Riverpod 3.x removed the `.stream` modifier that would have let this
  /// tap into that provider's existing stream directly, so this calls
  /// [CabinRealtimeRepository.watchStationCabins] a second time instead
  /// and filters it down to "this one cabin just became free" — the
  /// door-sensor-close signal FR-PAY-06 needs. Two lightweight
  /// subscriptions to the same channel for the duration of one active
  /// session is an accepted, documented minor inefficiency, not a
  /// correctness issue — simpler than threading a shared stream through
  /// Riverpod's current API.
  Stream<void> _cabinFreedStream(WidgetRef ref, String cabinId) {
    return ref
        .read(cabinRealtimeRepositoryProvider)
        .watchStationCabins(place.id)
        .where(
          (update) =>
              update.cabinId == cabinId &&
              update.occupancyStatus == CabinOccupancyStatus.free,
        );
  }

  Future<void> _openRoute(BuildContext context, AppLocalizations l10n) async {
    final Uri geoUri = Uri(
      scheme: "geo",
      host: "${place.position.latitude},${place.position.longitude}",
      queryParameters: <String, String>{
        "q":
            "${place.position.latitude},${place.position.longitude}"
            "(${place.name.forLanguageCode(Localizations.localeOf(context).languageCode)})",
      },
    );
    final Uri webFallbackUri = Uri.parse(
      "https://www.openstreetmap.org/?mlat=${place.position.latitude}"
      "&mlon=${place.position.longitude}#map=17/${place.position.latitude}/${place.position.longitude}",
    );

    final bool launched =
        await launchUrl(geoUri, mode: LaunchMode.externalApplication) ||
        await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.placeDetailRouteUnavailable)));
    }
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
  Widget build(BuildContext context, WidgetRef ref) {
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
              if (AppEnv.useMockPlaceDetail)
                Padding(
                  padding: const EdgeInsets.only(bottom: RahatiSpacing.space2),
                  child: _MockDataBanner(label: l10n.placeDetailMockDataBanner),
                ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      place.name.forLanguageCode(languageCode),
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
              Row(
                children: <Widget>[
                  Icon(
                    place.averageRating != null
                        ? Icons.star
                        : Icons.star_border,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: RahatiSpacing.space1),
                  Text(
                    place.averageRating != null
                        ? place.averageRating!.toStringAsFixed(1)
                        : l10n.placeDetailNoReviews,
                    style: textTheme.bodyMedium,
                  ),
                  if (place.averageRating != null) ...<Widget>[
                    const SizedBox(width: RahatiSpacing.space1),
                    Text(
                      "(${l10n.placeDetailReviewCount(place.reviewCount)})",
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (place.tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: RahatiSpacing.space3),
                Wrap(
                  spacing: RahatiSpacing.space2,
                  runSpacing: RahatiSpacing.space2,
                  children: <Widget>[
                    for (final String tag in place.tags)
                      Chip(
                        label: Text(_tagLabel(l10n, tag)),
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: RahatiSpacing.space3),
              _PlaceDetailExtra(place: place),
              _InfoRow(
                icon: place.isFree ? Icons.money_off : Icons.payments_outlined,
                label: place.isFree
                    ? l10n.placeDetailFree
                    : l10n.placeDetailPaid,
              ),
              _InfoRow(
                icon: Icons.social_distance,
                label: _formatDistance(place.distanceMeters),
              ),
              const SizedBox(height: RahatiSpacing.space4),
              // US-04.1 — shown only for a station with at least one
              // cabin (nothing to scan/unlock at a third-party place or
              // a station without cabins). `maybeWhen`/`orElse` rather
              // than `.when` — loading/error states already render via
              // `_PlaceDetailExtra` above; this button simply stays
              // absent until real cabin data resolves, no duplicate
              // loading/error UI.
              if (place.placeKind == PlaceKind.station)
                ref
                    .watch(stationDetailProvider(place.id))
                    .maybeWhen(
                      data: (detail) => detail.cabins.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(
                                bottom: RahatiSpacing.space3,
                              ),
                              child: FilledButton.icon(
                                onPressed: () => _scanQr(context, ref, l10n),
                                icon: const Icon(Icons.qr_code_scanner),
                                label: Text(l10n.placeDetailScanQr),
                              ),
                            )
                          : const SizedBox.shrink(),
                      orElse: () => const SizedBox.shrink(),
                    ),
              FilledButton.icon(
                onPressed: () => _openRoute(context, l10n),
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

/// US-01.2.2/US-01.2.3 — the lazily-fetched cabin list (station) or
/// declarative status (third-party place), inserted between the tag chips
/// and the free/paid + distance rows, matching SCR-005/SCR-006's layout.
class _PlaceDetailExtra extends ConsumerWidget {
  const _PlaceDetailExtra({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return switch (place.placeKind) {
      PlaceKind.station =>
        ref
            .watch(stationDetailProvider(place.id))
            .when(
              data: (detail) => _StationCabins(detail: detail),
              loading: () => _DetailStatusLine(
                icon: null,
                label: l10n.placeDetailDetailLoading,
              ),
              error: (error, stackTrace) => _DetailStatusLine(
                icon: Icons.error_outline,
                label: l10n.placeDetailDetailError,
              ),
            ),
      PlaceKind.thirdPartyPlace =>
        ref
            .watch(thirdPartyPlaceDetailProvider(place.id))
            .when(
              data: (detail) => _DeclaredStatusChip(detail: detail),
              loading: () => _DetailStatusLine(
                icon: null,
                label: l10n.placeDetailDetailLoading,
              ),
              error: (error, stackTrace) => _DetailStatusLine(
                icon: Icons.error_outline,
                label: l10n.placeDetailDetailError,
              ),
            ),
    };
  }
}

/// US-04.5 (FR-PAY-05) — a [ConsumerStatefulWidget], not stateless: it
/// accumulates a running set of live occupancy overrides
/// (`cabinOccupancyUpdatesProvider`, `station:{stationId}:cabins`
/// Realtime channel) on top of [detail]'s once-fetched cabin list, so a
/// cabin's status updates in place without the sheet needing to be
/// closed and reopened (or `stationDetailProvider` re-fetched).
class _StationCabins extends ConsumerStatefulWidget {
  const _StationCabins({required this.detail});

  final StationDetail detail;

  @override
  ConsumerState<_StationCabins> createState() => _StationCabinsState();
}

class _StationCabinsState extends ConsumerState<_StationCabins> {
  final Map<String, CabinOccupancyStatus> _liveOverrides =
      <String, CabinOccupancyStatus>{};

  @override
  Widget build(BuildContext context) {
    final StationDetail detail = widget.detail;
    if (detail.cabins.isEmpty) return const SizedBox.shrink();

    ref.listen<AsyncValue<CabinOccupancyUpdate>>(
      cabinOccupancyUpdatesProvider(detail.summary.id),
      (previous, next) {
        next.whenData((update) {
          setState(
            () => _liveOverrides[update.cabinId] = update.occupancyStatus,
          );
        });
      },
    );

    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Cabin? pricedCabin = detail.cabins
        .where((c) => c.isPaid && c.price != null)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: RahatiSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final Cabin cabin in detail.cabins)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: RahatiSpacing.space1,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    _cabinTypeIcon(cabin.type),
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: RahatiSpacing.space2),
                  Expanded(
                    child: Text(
                      l10n.placeDetailCabinLabel(cabin.code),
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  CabinStatusIndicator(
                    status: _liveOverrides[cabin.id] ?? cabin.occupancyStatus,
                  ),
                ],
              ),
            ),
          if (pricedCabin != null) ...<Widget>[
            const SizedBox(height: RahatiSpacing.space1),
            _InfoRow(
              icon: Icons.payments_outlined,
              label:
                  "${_formatMoney(pricedCabin.price!)} · "
                  "${l10n.placeDetailPaymentCard}, ${l10n.placeDetailPaymentWallet}",
            ),
          ],
        ],
      ),
    );
  }

  IconData _cabinTypeIcon(CabinType type) {
    return switch (type) {
      CabinType.men => Icons.man,
      CabinType.women => Icons.woman,
      CabinType.pmr => Icons.accessible,
      CabinType.slatoki => Icons.mosque,
    };
  }

  String _formatMoney(Money money) => "${money.amount} ${money.currency}";
}

class _DeclaredStatusChip extends StatelessWidget {
  const _DeclaredStatusChip({required this.detail});

  final ThirdPartyPlaceDetail detail;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String label = switch (detail.declaredStatus) {
      DeclaredStatus.open => l10n.placeDetailDeclaredStatusOpen,
      DeclaredStatus.closed => l10n.placeDetailDeclaredStatusClosed,
      DeclaredStatus.unknown => l10n.placeDetailDeclaredStatusUnknown,
    };
    final String sourceCaption = switch (detail.statusSource) {
      StatusSource.community => l10n.placeDetailStatusSourceCommunity,
      StatusSource.ownerDeclared => l10n.placeDetailStatusSourceOwnerDeclared,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: RahatiSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Outlined, not filled — visually distinct from a station's
          // IoT-verified CabinStatusIndicator, per SCR-006's explicit
          // "declarative, not IoT-verified" distinction.
          Chip(
            label: Text(label),
            backgroundColor: Colors.transparent,
            side: BorderSide(color: colorScheme.outline),
          ),
          const SizedBox(height: RahatiSpacing.space1),
          Text(
            sourceCaption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatusLine extends StatelessWidget {
  const _DetailStatusLine({required this.icon, required this.label});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // Semantics(liveRegion: true, label:) + ExcludeSemantics (US-06.4
    // finding) — this line's content changes from a loading state to
    // either real data or this error/loading text with no user
    // interaction, so a screen reader must announce it when it changes,
    // not only if the user happens to be focused on it — same discipline
    // as `map_screen.dart`'s `_StatusBanner` (finding F24). Covers both
    // this widget's loading and error variants identically, since both are
    // the same kind of unprompted, asynchronous content change.
    return Semantics(
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: RahatiSpacing.space3),
          child: Row(
            children: <Widget>[
              if (icon == null)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Icon(icon, size: 16, color: colorScheme.error),
              const SizedBox(width: RahatiSpacing.space2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockDataBanner extends StatelessWidget {
  const _MockDataBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RahatiSpacing.space3,
        vertical: RahatiSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: RahatiShape.fullRadius,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.science_outlined,
            size: 16,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: RahatiSpacing.space1),
          // `Flexible`, not a bare `Text` — this banner's full sentence is
          // wider than some devices' sheet width; without it the text
          // overflows the row instead of wrapping (caught via an on-device
          // screenshot, not review).
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RahatiSpacing.space1),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: RahatiSpacing.space2),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
