import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/router/app_router.dart";
import "../../../../core/theme/color_tokens.dart";
import "../../../../core/theme/motion_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/access_session.dart";
import "../../domain/repositories/access_session_repository.dart";
import "../providers/access_session_providers.dart";

/// SCR-014 — Cabin Availability Confirmation (US-04.2, FR-PAY-02), pushed
/// by [QrScannerScreen] once it has a client-validated QR value (scanned
/// or manually entered). The actual availability check is **not** a
/// separate call from here — per
/// docs/architecture/sequence-diagrams.md §1 and
/// `AccessSessionRepository`'s own doc comment, the backend resolves it
/// synchronously inside the same `POST /access-sessions` call this screen
/// triggers via [qrScanNotifierProvider].
///
/// Pops with the created [AccessSession] once `available` (briefly shown,
/// then auto-advances per the wireframe), or never pops on `unavailable` —
/// that state's "Retour à la carte" button exits the whole scan flow via
/// `context.go(AppRoutePaths.map)` rather than handing control back to
/// SCR-013, since re-scanning the same now-unavailable cabin isn't a
/// useful next step. SCR-015's real navigation (US-04.3) is deliberately
/// not wired here yet — this story's scope ends at confirming
/// availability, same boundary discipline as US-04.1's `QrScannerScreen`
/// doc comment.
class CabinAvailabilityScreen extends ConsumerStatefulWidget {
  const CabinAvailabilityScreen({required this.rawQrValue, super.key});

  final String rawQrValue;

  @override
  ConsumerState<CabinAvailabilityScreen> createState() =>
      _CabinAvailabilityScreenState();
}

class _CabinAvailabilityScreenState
    extends ConsumerState<CabinAvailabilityScreen> {
  @override
  void initState() {
    super.initState();
    // Post-frame, not called directly — `submit`/`reset` synchronously
    // assign to `qrScanNotifierProvider`'s state, which must not happen
    // while this widget's own first build is still in flight. `reset()`
    // first clears any stale `AsyncData` left over from a prior scan
    // attempt in the same app session (the provider is a singleton, not
    // scoped per-attempt) — the very first frame can still flash that
    // stale state for one frame before this callback runs; harmless and
    // not worth a bigger provider-scoping change to eliminate.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(qrScanNotifierProvider.notifier).reset();
      unawaited(
        ref.read(qrScanNotifierProvider.notifier).submit(widget.rawQrValue),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<AccessSession?> state = ref.watch(qrScanNotifierProvider);

    ref.listen<AsyncValue<AccessSession?>>(qrScanNotifierProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (session) {
          if (session == null) return;
          // `NavigatorState` captured synchronously, before the delay —
          // not `BuildContext` itself — so there's nothing unsafe to use
          // once the gap closes.
          final NavigatorState navigator = Navigator.of(context);
          // Brief success flash before auto-advancing, per SCR-014's
          // "auto-advances ... within ~1s" wireframe language.
          Future.delayed(RahatiMotionDuration.extraLong1, () {
            if (mounted) navigator.pop(session);
          });
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(RahatiSpacing.space6),
            child: state.when(
              data: (session) => session == null
                  ? _StatusView(
                      icon: Icons.hourglass_top_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      message: l10n.cabinAvailabilityCheckingMessage,
                      showProgress: true,
                    )
                  : _StatusView(
                      icon: Icons.check_circle_outline,
                      color: Theme.of(
                        context,
                      ).extension<RahatiFunctionalColors>()!.success,
                      message: l10n.cabinAvailabilityAvailableMessage,
                      showProgress: false,
                    ),
              loading: () => _StatusView(
                icon: Icons.hourglass_top_outlined,
                color: Theme.of(context).colorScheme.primary,
                message: l10n.cabinAvailabilityCheckingMessage,
                showProgress: true,
              ),
              error: (error, stackTrace) => _UnavailableView(
                message: error is CabinUnavailableFailure
                    ? l10n.cabinAvailabilityUnavailableMessage
                    : l10n.qrScannerGenericError,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bespoke "Cabin-Status Indicator" (large, centered) the wireframe
/// calls for — scoped to this screen only (not `map_discovery`'s
/// `CabinStatusIndicator`, which models a different concept: an occupied
/// cabin's live free/occupied/out-of-service dot, not this flow's
/// checking/available transient states).
class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.color,
    required this.message,
    required this.showProgress,
  });

  final IconData icon;
  final Color color;
  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 64, color: color),
          const SizedBox(height: RahatiSpacing.space4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (showProgress) ...<Widget>[
            const SizedBox(height: RahatiSpacing.space6),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(),
            ),
          ],
        ],
      ),
    );
  }
}

/// SCR-014's `unavailable` state — also reused for any other
/// [AccessSessionRepositoryFailure] (no dedicated wireframe state exists
/// for a generic network/backend failure at this step, and re-scanning
/// the same cabin isn't a more useful recovery than returning to the map
/// either way).
class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(RahatiSpacing.space4),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: RahatiSpacing.space4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: RahatiSpacing.space6),
          FilledButton(
            onPressed: () => context.go(AppRoutePaths.map),
            child: Text(l10n.cabinAvailabilityBackToMapButton),
          ),
        ],
      ),
    );
  }
}
