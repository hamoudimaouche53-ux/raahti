import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";

import "../../../../core/router/app_router.dart";
import "../../../../l10n/app_localizations.dart";
import "../../../map_discovery/domain/entities/review.dart";
import "../../../map_discovery/presentation/providers/place_detail_providers.dart";
import "../../../map_discovery/presentation/screens/submit_review_screen.dart";

/// SCR-023 — My Reviews (US-05.2).
///
/// Each row shows the resolved [Review.placeName], the star rating, the
/// comment, and the submission date, plus edit/delete actions — edit
/// pushes [SubmitReviewScreen] in its edit mode (see
/// [ExistingReviewArgs]'s own doc comment) rather than a second
/// near-duplicate screen.
class MyReviewsScreen extends ConsumerStatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  ConsumerState<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends ConsumerState<MyReviewsScreen> {
  late Future<List<Review>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(reviewRepositoryProvider).getMyReviews();
  }

  void _reload() {
    setState(() {
      _future = ref.read(reviewRepositoryProvider).getMyReviews();
    });
  }

  Future<void> _edit(Review review, String languageCode) async {
    await context.push<void>(
      AppRoutePaths.submitReview,
      extra: SubmitReviewArgs(
        placeKind: review.placeKind,
        placeId: review.placeId,
        placeName: review.placeName.forLanguageCode(languageCode),
        existingReview: ExistingReviewArgs(
          reviewId: review.id,
          rating: review.rating,
          comment: review.comment,
        ),
      ),
    );
    if (!mounted) return;
    _reload();
  }

  Future<void> _delete(Review review) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.myReviewsDeleteConfirmTitle),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.genericCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.genericDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(reviewRepositoryProvider)
        .deleteReview(
          reviewId: review.id,
          placeKind: review.placeKind,
          placeId: review.placeId,
        );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myReviewsTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Review>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<Review> reviews = snapshot.data!;
            if (reviews.isEmpty) {
              return Center(child: Text(l10n.myReviewsEmptyState));
            }
            return ListView(
              children: <Widget>[
                for (final Review review in reviews)
                  ListTile(
                    title: Text(review.placeName.forLanguageCode(languageCode)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Semantics(
                          label: l10n.submitReviewStarSemanticLabel(
                            review.rating,
                          ),
                          child: ExcludeSemantics(
                            child: Row(
                              children: List<Widget>.generate(
                                5,
                                (index) => Icon(
                                  index < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          review.comment?.isNotEmpty == true
                              ? "${review.comment} — ${DateFormat.yMd(languageCode).format(review.createdAt)}"
                              : DateFormat.yMd(
                                  languageCode,
                                ).format(review.createdAt),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: l10n.genericEditButton,
                          onPressed: () => _edit(review, languageCode),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.genericDeleteButton,
                          onPressed: () => _delete(review),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
