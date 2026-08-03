import "package:flutter/material.dart";

import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";

/// Emergency tab — zero-logic placeholder, per ADR-0024
/// (docs/adr/0024-bottom-navigation-shell-staging.md).
///
/// EPIC-03 (Mode Urgence) is V1.1-scoped, not V1 — it does not exist yet.
/// This screen exists only so the bottom navigation bar can have its
/// spec-mandated 4 fixed destinations (docs/design/component-library.md §5)
/// from the moment EPIC-02 ships. It contains no business logic: no fake
/// facility lookup, no mocked discount eligibility, nothing EPIC-03 will
/// need to un-fake later — replaced wholesale by the real Emergency screen
/// when that epic is implemented.
class EmergencyPlaceholderScreen extends StatelessWidget {
  const EmergencyPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            label:
                "${l10n.emergencyPlaceholderTitle}. ${l10n.emergencyPlaceholderBody}",
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.all(RahatiSpacing.space6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.emergency_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: RahatiSpacing.space4),
                    Text(
                      l10n.emergencyPlaceholderTitle,
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: RahatiSpacing.space2),
                    Text(
                      l10n.emergencyPlaceholderBody,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
