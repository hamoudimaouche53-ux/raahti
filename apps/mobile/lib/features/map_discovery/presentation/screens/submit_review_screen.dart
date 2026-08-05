import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/place.dart" show PlaceKind;
import "../providers/place_detail_providers.dart";

/// `state.extra` payload for [AppRoutePaths.submitReview] — a small typed
/// carrier, same precedent as every other route's `*Args` class.
///
/// Reached today only from SCR-019's "Laisser un avis" (always a
/// station — see `UnlockConfirmationArgs`'s own doc comment for why
/// [placeKind] doesn't need to be threaded there). [placeKind] is still a
/// real, honored field here (not hard-coded inside this screen) so a
/// future entry point from SCR-005/006 (a third-party place's own detail
/// sheet, per this screen's wireframe) needs no change to this screen
/// itself.
class SubmitReviewArgs {
  const SubmitReviewArgs({
    required this.placeKind,
    required this.placeId,
    required this.placeName,
  });

  final PlaceKind placeKind;
  final String placeId;
  final String placeName;
}

/// SCR-007 — Submit Review (US-05.2, FR-PLC-01).
class SubmitReviewScreen extends ConsumerStatefulWidget {
  const SubmitReviewScreen({required this.args, super.key});

  final SubmitReviewArgs args;

  @override
  ConsumerState<SubmitReviewScreen> createState() =>
      _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends ConsumerState<SubmitReviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      await ref
          .read(reviewRepositoryProvider)
          .submitReview(
            placeKind: widget.args.placeKind,
            placeId: widget.args.placeId,
            rating: _rating,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.submitReviewSuccessSnackbar)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.submitReviewErrorSnackbar)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.submitReviewTitle),
        leading: CloseButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RahatiSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.args.placeName,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: RahatiSpacing.space6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(5, (index) {
                  final int starValue = index + 1;
                  final bool filled = starValue <= _rating;
                  return Semantics(
                    button: true,
                    label: l10n.submitReviewStarSemanticLabel(starValue),
                    selected: filled,
                    child: IconButton(
                      iconSize: 40,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: Icon(
                        filled ? Icons.star : Icons.star_border,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => setState(() => _rating = starValue),
                    ),
                  );
                }),
              ),
              const SizedBox(height: RahatiSpacing.space6),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.submitReviewCommentLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: (_rating == 0 || _submitting) ? null : _submit,
                // While submitting, the child has no Text — a bare
                // CircularProgressIndicator carries no semantics label of
                // its own, so the button lost its accessible name
                // entirely (WCAG 4.1.2, US-06.4 finding F18). Wrapping
                // just the spinner keeps the button's name stable across
                // both states without touching FilledButton's own
                // button-role/enabled semantics.
                child: _submitting
                    ? Semantics(
                        label: l10n.submitReviewPublishButton,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(l10n.submitReviewPublishButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
