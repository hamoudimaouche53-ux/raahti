import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:intl/intl.dart";

import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/visit.dart";
import "../providers/profile_providers.dart";

/// SCR-021 — Visit History (US-05.2).
///
/// Grouped by month with `titleSmall` section headers, per the wireframe.
/// [VisitHistoryRepository] has no real REST implementation (API
/// Contract Gap, see `VisitHistoryEndpointNotSpecifiedFailure`'s own doc
/// comment) — this screen's error state doubles as that gap's user-facing
/// surface until a real endpoint exists.
class VisitHistoryScreen extends ConsumerWidget {
  const VisitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Visit>> state = ref.watch(visitHistoryProvider);
    final String languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.visitHistoryTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(RahatiSpacing.space6),
              child: Text(
                l10n.visitHistoryEmptyState,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (visits) {
            if (visits.isEmpty) {
              return Center(child: Text(l10n.visitHistoryEmptyState));
            }
            final List<Visit> sorted = [...visits]
              ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
            return ListView(children: _grouped(sorted, languageCode, l10n));
          },
        ),
      ),
    );
  }

  List<Widget> _grouped(
    List<Visit> visits,
    String languageCode,
    AppLocalizations l10n,
  ) {
    final List<Widget> children = [];
    String? currentMonthKey;
    for (final Visit visit in visits) {
      final String monthKey =
          "${visit.occurredAt.year}-${visit.occurredAt.month}";
      if (monthKey != currentMonthKey) {
        currentMonthKey = monthKey;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RahatiSpacing.space4,
              RahatiSpacing.space4,
              RahatiSpacing.space4,
              RahatiSpacing.space2,
            ),
            child: Semantics(
              header: true,
              child: Text(
                DateFormat.yMMMM(languageCode).format(visit.occurredAt),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      }
      children.add(
        ListTile(
          title: Text(visit.placeName),
          subtitle: Text(
            DateFormat.yMd(languageCode).add_Hm().format(visit.occurredAt),
          ),
          trailing: Text(
            visit.amount == null
                ? l10n.sessionCompleteAmountFree
                : "${visit.amount!.amount} ${visit.amount!.currency}",
          ),
        ),
      );
    }
    return children;
  }
}
