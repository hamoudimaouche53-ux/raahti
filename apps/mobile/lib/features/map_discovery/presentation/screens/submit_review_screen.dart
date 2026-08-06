import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/place.dart" show PlaceKind;
import "../providers/place_detail_providers.dart";

/// Carries an already-submitted review's own fields into
/// [SubmitReviewScreen]'s edit mode (SCR-023's "edit" entry point,
/// EPIC-05 US-05.2) — when non-null on [SubmitReviewArgs], the screen
/// pre-fills the rating/comment from these and calls
/// `ReviewRepository.updateReview` instead of `submitReview` on save.
class ExistingReviewArgs {
  const ExistingReviewArgs({
    required this.reviewId,
    required this.rating,
    required this.comment,
  });

  final String reviewId;
  final int rating;
  final String? comment;
}

/// `state.extra` payload for [AppRoutePaths.submitReview] — a small typed
/// carrier, same precedent as every other route's `*Args` class.
///
/// Reached both from SCR-019's "Laisser un avis" (a new review — see
/// `UnlockConfirmationArgs`'s own doc comment for why [placeKind] doesn't
/// need to be threaded there) and from SCR-023's per-row edit action (an
/// existing review, [existingReview] non-null).
class SubmitReviewArgs {
  const SubmitReviewArgs({
    required this.placeKind,
    required this.placeId,
    required this.placeName,
    this.existingReview,
  });

  final PlaceKind placeKind;
  final String placeId;
  final String placeName;

  /// Non-null switches this screen into edit mode — see
  /// [ExistingReviewArgs]'s own doc comment.
  final ExistingReviewArgs? existingReview;
}

/// SCR-007 — Submit Review (US-05.2, FR-PLC-01). Doubles as SCR-023's
/// edit-review screen when [SubmitReviewScreen.args].existingReview is
/// non-null, rather than a second near-duplicate screen.
class SubmitReviewScreen extends ConsumerStatefulWidget {
  const SubmitReviewScreen({required this.args, super.key});

  final SubmitReviewArgs args;

  @override
  ConsumerState<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends ConsumerState<SubmitReviewScreen> {
  late final TextEditingController _commentController = TextEditingController(
    text: widget.args.existingReview?.comment ?? "",
  );
  late int _rating = widget.args.existingReview?.rating ?? 0;
  bool _submitting = false;

  bool get _isEditing => widget.args.existingReview != null;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      final String? comment = _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim();
      final ExistingReviewArgs? existingReview = widget.args.existingReview;
      if (existingReview == null) {
        await ref
            .read(reviewRepositoryProvider)
            .submitReview(
              placeKind: widget.args.placeKind,
              placeId: widget.args.placeId,
              placeName: widget.args.placeName,
              rating: _rating,
              comment: comment,
            );
      } else {
        await ref
            .read(reviewRepositoryProvider)
            .updateReview(
              reviewId: existingReview.reviewId,
              placeKind: widget.args.placeKind,
              placeId: widget.args.placeId,
              placeName: widget.args.placeName,
              rating: _rating,
              comment: comment,
            );
      }
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? l10n.submitReviewUpdateSuccessSnackbar
                : l10n.submitReviewSuccessSnackbar,
          ),
        ),
      );
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
    final String publishButtonLabel = _isEditing
        ? l10n.submitReviewUpdateButton
        : l10n.submitReviewPublishButton;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.submitReviewEditTitle : l10n.submitReviewTitle,
        ),
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
                        label: publishButtonLabel,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Text(publishButtonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
