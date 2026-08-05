import "dart:async";

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../core/router/app_router.dart";
import "../../../../core/theme/color_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/money.dart";
import "session_complete_screen.dart";

/// SCR-017 — Unlock Confirmation / Access Active (US-04.4, FR-PAY-04).
///
/// Pushed once a cabin is confirmed `unlocked` — for a free cabin,
/// directly from `POST /access-sessions` (Feature 12/14's contract); for
/// a paid one, from `POST /access-sessions/{id}/payments`'s success
/// response (Feature 15). Per `docs/architecture/sequence-diagrams.md`
/// §1, the backend orchestrates authorize → capture → unlock-order →
/// ack-wait entirely within that single request/response — by the time
/// either caller navigates here, the unlock has **already succeeded**.
/// There is therefore no reachable `unlock-failed` state from this
/// screen in this app's architecture (unlike SCR-017's own wireframe
/// listing one) — a paid cabin's unlock failure surfaces as
/// `UnlockFailedRefundedFailure` from `PaymentProcessingScreen`'s call
/// instead (SCR-018, already handled there, Feature 15). This is a
/// deliberate simplification following from the single-call design, not
/// a silently dropped state — flagged here and in the implementation log.
///
/// The `unlocking` state's determinate 4-step progress (Component
/// Library §7) is therefore a **fixed-duration visual sequence**, not a
/// second network wait — the result is already known. [kUnlockWaitTimeout]
/// (ADR-0026 Decision 1's named, documented 30s bound) still guards it
/// defensively: if a future story replaces this with a genuine
/// async/polling-based confirmation, the guard is already in place and
/// only needs its wait source swapped, not re-invented.
///
/// Navigates to SCR-019 (`SessionCompleteScreen`, US-04.6) on whichever
/// comes first: the user tapping "J'ai terminé", or [cabinFreedStream]
/// emitting (the real or mock door-sensor-close broadcast, FR-PAY-06).
/// Per ADR-0026 Decision 2, there is deliberately **no** invented
/// auto-close timeout/countdown here — this screen only ever reacts to
/// one of those two real events, however long either takes.
///
/// [cabinFreedStream] is a plain, generic `Stream<void>` — not a
/// `map_discovery` type — so this file never imports from
/// `map_discovery` (this feature's established one-directional
/// dependency: `map_discovery` reads from `access_payment`, never the
/// reverse; see `PlaceDetailSheet`'s own doc comment). `PlaceDetailSheet`
/// is what actually knows about `cabinOccupancyUpdatesProvider`/
/// `CabinOccupancyUpdate` — it filters that Realtime stream down to "this
/// cabin just became free" before handing off a bare `Stream<void>` here.
/// `state.extra` payload for [AppRoutePaths.accessPaymentUnlock] — a
/// small typed carrier beats an untyped `Map` cast, same precedent as
/// `PaymentProcessingArgs`.
class UnlockConfirmationArgs {
  const UnlockConfirmationArgs({
    required this.cabinCode,
    required this.stationName,
    required this.startedAt,
    required this.amount,
    required this.cabinFreedStream,
    required this.placeId,
    required this.placeName,
  });

  final String cabinCode;
  final String stationName;
  final DateTime startedAt;
  final Money? amount;
  final Stream<void> cabinFreedStream;

  /// Feeds `SessionCompleteArgs.placeId`/`placeName` for SCR-019's
  /// "Laisser un avis" → SCR-007 (Submit Review, US-05.2, Feature 20).
  /// Plain strings, not `map_discovery`'s `PlaceKind` — this screen never
  /// imports `map_discovery` (see this class's own doc comment); every
  /// place reachable through this screen is a station (only stations
  /// have cabins/QR codes to unlock), so `SubmitReviewScreen` assumes
  /// `PlaceKind.station` for this navigation path without needing the
  /// enum threaded through.
  final String placeId;
  final String placeName;
}

class UnlockConfirmationScreen extends StatefulWidget {
  const UnlockConfirmationScreen({
    required this.cabinCode,
    required this.stationName,
    required this.startedAt,
    required this.amount,
    required this.cabinFreedStream,
    required this.placeId,
    required this.placeName,
    super.key,
  });

  final String cabinCode;
  final String stationName;
  final DateTime startedAt;
  final Money? amount;
  final Stream<void> cabinFreedStream;
  final String placeId;
  final String placeName;

  /// ADR-0026 Decision 1 — declared once, named, documented, trivially
  /// replaceable once a real backend/hardware SLA exists (Risk R-11).
  static const Duration kUnlockWaitTimeout = Duration(seconds: 30);

  /// 4 steps × `RahatiMotionDuration.medium4` (400ms) each — the fixed
  /// visual sequence described above, well under [kUnlockWaitTimeout].
  static const Duration _unlockSequenceDuration = Duration(
    milliseconds: 1600,
  );

  @override
  State<UnlockConfirmationScreen> createState() =>
      _UnlockConfirmationScreenState();
}

class _UnlockConfirmationScreenState extends State<UnlockConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController = AnimationController(
    vsync: this,
    duration: UnlockConfirmationScreen._unlockSequenceDuration,
  )..forward();
  bool _unlocking = true;

  /// ADR-0026 Decision 1's 30s bound, wired for real (not decorative) —
  /// always loses the race against the ~1.6s visual sequence in this
  /// app's single-call architecture (the result is already known before
  /// this screen ever mounts), but a future story swapping this for a
  /// genuine async/polling wait only needs to replace what this timer
  /// races against, not add the guard itself.
  Timer? _waitTimeoutTimer;

  /// FR-PAY-06 (US-04.6) — the door-sensor-close broadcast (or its mock
  /// equivalent). Subscribed for this screen's entire lifetime; whichever
  /// fires first between this and "J'ai terminé" ends the session.
  StreamSubscription<void>? _cabinFreedSubscription;

  @override
  void initState() {
    super.initState();
    _progressController.addStatusListener(_onAnimationStatus);
    _waitTimeoutTimer = Timer(
      UnlockConfirmationScreen.kUnlockWaitTimeout,
      () {
        if (mounted && _unlocking) setState(() => _unlocking = false);
      },
    );
    _cabinFreedSubscription = widget.cabinFreedStream.listen((_) {
      _completeSession();
    });
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _unlocking = false);
    }
  }

  /// Common exit for both the manual "J'ai terminé" action and the
  /// door-sensor-close broadcast — "visually identical either way," per
  /// SCR-019's own wireframe, so both paths land here.
  void _completeSession() {
    if (!mounted) return;
    context.go(
      AppRoutePaths.sessionComplete,
      extra: SessionCompleteArgs(
        amount: widget.amount,
        duration: DateTime.now().difference(widget.startedAt),
        placeId: widget.placeId,
        placeName: widget.placeName,
      ),
    );
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_onAnimationStatus);
    _progressController.dispose();
    _waitTimeoutTimer?.cancel();
    unawaited(_cabinFreedSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RahatiFunctionalColors functionalColors = Theme.of(
      context,
    ).extension<RahatiFunctionalColors>()!;

    return PopScope(
      // Matches SCR-016's "no back gesture" precedent while the unlock
      // sequence animates — once settled, the only way out is "J'ai
      // terminé" (ADR-0026 Decision 2: no invented auto-close, manual
      // action only).
      canPop: false,
      child: Scaffold(
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
                  Semantics(
                    liveRegion: true,
                    label: l10n.unlockConfirmationSuccessAnnouncement,
                    child: ExcludeSemantics(
                      child: Text(
                        l10n.unlockConfirmationHeadline,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: RahatiSpacing.space2),
                  Text(
                    l10n.placeDetailCabinLabel(widget.cabinCode),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    widget.stationName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: RahatiSpacing.space6),
                  if (_unlocking)
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) => LinearProgressIndicator(
                        value: _progressController.value,
                      ),
                    )
                  else
                    Semantics(
                      liveRegion: true,
                      label: l10n.unlockConfirmationSessionActive,
                      child: ExcludeSemantics(
                        child: Text(
                          l10n.unlockConfirmationSessionActive,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  const SizedBox(height: RahatiSpacing.space8),
                  TextButton(
                    onPressed: _completeSession,
                    child: Text(l10n.unlockConfirmationFinishButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
