import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/router/app_router.dart";
import "../../../../core/theme/color_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/slatoki_place.dart";
import "../../domain/repositories/slatoki_place_repository.dart";
import "../providers/slatoki_place_providers.dart";
import "../widgets/qibla_compass.dart";
import "../widgets/slatoki_filter_tabs.dart";
import "../widgets/slatoki_place_detail_sheet.dart";
import "../widgets/slatoki_place_list_item.dart";

/// SCR-008 — Slatoki Tab (docs/design/screen-inventory.md, supports
/// US-02.1.1, 02.1.3, 02.1.4, 02.1.5 — docs/design/wireframes/mobile-slatoki.md#scr-008-slatoki-tab-list--qibla-widget-flagship).
///
/// **US-02.1.1** delivers the screen's own existence as a dedicated
/// bottom-nav destination. **US-02.1.2** adds the compact Qibla Compass
/// widget card. **US-02.1.3** adds the Prayer/Wudu filter tab row and the
/// real, Riverpod-driven list of Slatoki-qualified places it narrows.
/// **US-02.1.4** wires each list item's tap to SCR-010 ([SlatokiPlaceDetailSheet])
/// and adds the verified-mosque "Femmes ✓" badge ([SlatokiPlaceListItem]).
///
/// The Slatoki Tent-Status Card (US-02.1.5, Component Library §9.2) is a
/// separate, not-yet-implemented story that will extend both the list item
/// and the detail sheet for RAHETI-tent places specifically.
class SlatokiScreen extends ConsumerWidget {
  const SlatokiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final RahatiFunctionalColors functionalColors = Theme.of(
      context,
    ).extension<RahatiFunctionalColors>()!;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<SlatokiPlace>> filtered = ref.watch(
      filteredSlatokiPlacesProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.slatokiTabTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: functionalColors.slatoki, height: 3),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RahatiSpacing.space4,
                vertical: RahatiSpacing.space3,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: QiblaCompass(
                  mode: QiblaCompassMode.compact,
                  onTap: () => context.push(AppRoutePaths.slatokiQibla),
                ),
              ),
            ),
            const SlatokiFilterTabs(),
            const Divider(height: 1),
            Expanded(
              child: _Body(
                filtered: filtered,
                l10n: l10n,
                theme: textTheme,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.filtered,
    required this.l10n,
    required this.theme,
    required this.colorScheme,
  });

  final AsyncValue<List<SlatokiPlace>> filtered;
  final AppLocalizations l10n;
  final TextTheme theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // Checked *before* isLoading, deliberately: Riverpod 3.x's default
    // FutureProvider retry (`ProviderContainer.defaultRetry`, exponential
    // backoff up to 10 attempts) means a failing fetch can sit in
    // `AsyncLoading(error: ..., retrying: true)` — `isLoading` **and**
    // `hasError` both true at once — for several real seconds before
    // finally surfacing as `AsyncError`. Checking `hasError` first shows
    // the honest failure immediately instead of a spinner that hides it
    // through every retry attempt (a genuinely bad UX for a deterministic
    // failure like "no backend configured", which retrying can never fix).
    if (filtered.hasError) {
      return _Message(
        icon: Icons.error_outline,
        text: _errorLabel(l10n, filtered.error),
        theme: theme,
        colorScheme: colorScheme,
      );
    }
    if (filtered.isLoading && !filtered.hasValue) {
      return _Message(
        icon: Icons.mosque_outlined,
        text: l10n.slatokiPlacesLoading,
        theme: theme,
        colorScheme: colorScheme,
        showSpinner: true,
      );
    }
    final List<SlatokiPlace> places = filtered.value ?? const <SlatokiPlace>[];
    if (places.isEmpty) {
      return _Message(
        icon: Icons.mosque_outlined,
        text: l10n.slatokiEmptyState,
        theme: theme,
        colorScheme: colorScheme,
      );
    }
    return ListView.builder(
      itemCount: places.length,
      itemBuilder: (context, index) => SlatokiPlaceListItem(
        slatokiPlace: places[index],
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) =>
              SlatokiPlaceDetailSheet(slatokiPlace: places[index]),
        ),
      ),
    );
  }

  String _errorLabel(AppLocalizations l10n, Object? error) {
    return switch (error) {
      SlatokiApiNotConfiguredFailure() => l10n.slatokiPlacesErrorNotConfigured,
      _ => l10n.slatokiPlacesErrorGeneric,
    };
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    required this.theme,
    required this.colorScheme,
    this.showSpinner = false,
  });

  final IconData icon;
  final String text;
  final TextTheme theme;
  final ColorScheme colorScheme;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RahatiSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (showSpinner)
              CircularProgressIndicator(color: colorScheme.primary)
            else
              Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: RahatiSpacing.space4),
            Text(
              text,
              style: theme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
