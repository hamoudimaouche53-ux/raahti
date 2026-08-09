import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/router/app_router.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/access_session.dart";
import "../../domain/repositories/payment_repository.dart";
import "../providers/payment_providers.dart";

/// Popped by [PaymentProcessingScreen]'s [PaymentDeclinedFailure] variant
/// when the user taps "Réessayer" — signals the caller
/// (`PlaceDetailSheet`) to re-open SCR-015 with the same [AccessSession]
/// rather than re-scanning, per SCR-018's documented decline-retry
/// behavior ("retry re-opens SCR-015").
enum PaymentRetrySignal { retryMethodSelection }

/// `state.extra` payload for [AppRoutePaths.accessPaymentProcessing] —
/// two params, so a small typed carrier beats an untyped `Map` cast.
class PaymentProcessingArgs {
  const PaymentProcessingArgs({
    required this.accessSessionId,
    required this.paymentMethodId,
  });

  final String accessSessionId;
  // `null` for a free cabin (no saved method needed to authorize a $0
  // charge) — see `PaymentRepository`'s doc comment.
  final String? paymentMethodId;
}

/// SCR-016/018 — Payment Processing (US-04.3, FR-PAY-03/04) and its
/// payment-declined error variant (SCR-018's other variant,
/// unlock-failed-refunded, is also handled here since
/// [UnlockFailedRefundedFailure] can surface directly from this screen's
/// own `POST /access-sessions/{id}/payments` call — see
/// `PaymentRepository`'s doc comment).
///
/// Pops with the updated [AccessSession] on success (SCR-017's real
/// navigation is deliberately not wired here yet — US-04.4's job, same
/// boundary discipline as every prior deferred-scope note in this log),
/// [PaymentRetrySignal.retryMethodSelection] if the user wants to retry
/// with a different method, or `null` if they give up via "Retour à la
/// carte" (handled internally via `context.go`, so the push's Future is
/// abandoned rather than resolved — same pattern as
/// `CabinAvailabilityScreen`'s unavailable state).
class PaymentProcessingScreen extends ConsumerStatefulWidget {
  const PaymentProcessingScreen({
    required this.accessSessionId,
    required this.paymentMethodId,
    super.key,
  });

  final String accessSessionId;
  final String? paymentMethodId;

  @override
  ConsumerState<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState
    extends ConsumerState<PaymentProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Post-frame, not called directly — same synchronous-state-mutation
    // hazard `CabinAvailabilityScreen.initState` documents.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(paymentNotifierProvider.notifier).reset();
      ref
          .read(paymentNotifierProvider.notifier)
          .submit(
            accessSessionId: widget.accessSessionId,
            paymentMethodId: widget.paymentMethodId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<AccessSession?> state = ref.watch(paymentNotifierProvider);

    ref.listen<AsyncValue<AccessSession?>>(paymentNotifierProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (session) {
          if (session != null) Navigator.of(context).pop(session);
        },
      );
    });

    return PopScope(
      // SCR-016's documented "no back gesture while processing" state —
      // once a failure resolves, the back gesture is allowed again (the
      // on-screen buttons are the primary path, but there's no reason to
      // keep blocking it once nothing is in flight). Success is never
      // reached here long enough to matter — the listener above pops
      // this screen the instant `AsyncData` with a non-null session
      // arrives.
      canPop: state.hasError,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(RahatiSpacing.space6),
              child: state.when(
                data: (session) =>
                    _ProcessingView(message: l10n.paymentProcessingMessage),
                loading: () =>
                    _ProcessingView(message: l10n.paymentProcessingMessage),
                error: (error, stackTrace) => _PaymentFailedView(error: error),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // `label:` + `ExcludeSemantics` (not a bare `liveRegion: true`), matching
    // the pattern `map_screen.dart`'s `_StatusBanner` and
    // `unlock_confirmation_screen.dart` use — without `ExcludeSemantics` the
    // child `Text`'s own implicit semantics node would remain a second,
    // separate node alongside this explicit label, risking a
    // double-announcement (US-06.4 finding). Safe to exclude the whole
    // subtree here since it contains no independently-interactive control.
    return Semantics(
      label: message,
      liveRegion: true,
      child: ExcludeSemantics(
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

/// SCR-018 Payment Failed / Refund Notice.
class _PaymentFailedView extends StatelessWidget {
  const _PaymentFailedView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final String title = switch (error) {
      PaymentDeclinedFailure() => l10n.paymentFailedDeclinedTitle,
      UnlockFailedRefundedFailure() => l10n.paymentFailedUnlockTitle,
      _ => l10n.paymentFailedGenericTitle,
    };

    void onRetry() {
      if (error is UnlockFailedRefundedFailure) {
        // "retry re-opens SCR-013 QR scan" (wireframe) — the cabin's
        // state must be re-verified, not just re-paid.
        context.go(AppRoutePaths.accessPaymentScan);
      } else {
        // Payment-declined and generic-failure variants both retry via
        // "pick a different (or the same) method" — pops back up to
        // `PlaceDetailSheet`'s retry loop rather than navigating here.
        Navigator.of(context).pop(PaymentRetrySignal.retryMethodSelection);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // `label:` + `ExcludeSemantics` scoped to just the icon+title, not
        // the whole Column (US-06.4 finding — a bare `liveRegion: true`
        // here risked a double-announcement, same class of issue as
        // `_ProcessingView` above). Unlike that view, this one has two
        // actionable buttons below — wrapping the *entire* subtree in
        // `ExcludeSemantics` would have silently stripped their semantics
        // too, so only the decorative icon+title pair is scoped in.
        Semantics(
          label: title,
          liveRegion: true,
          child: ExcludeSemantics(
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
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: RahatiSpacing.space6),
        FilledButton(
          onPressed: onRetry,
          child: Text(l10n.paymentFailedRetryButton),
        ),
        const SizedBox(height: RahatiSpacing.space2),
        TextButton(
          onPressed: () => context.go(AppRoutePaths.map),
          child: Text(l10n.cabinAvailabilityBackToMapButton),
        ),
      ],
    );
  }
}
