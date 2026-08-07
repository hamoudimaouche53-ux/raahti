import "dart:async";

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../core/router/app_router.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../core/widgets/brand_logo.dart";
import "../../../../l10n/app_localizations.dart";

/// SCR-001 — Splash / Launch.
///
/// Traces to: docs/design/screen-inventory.md (SCR-001, supports
/// US-01.1.1), docs/design/wireframes/mobile-map-discovery.md#scr-001.
///
/// Full-bleed [ColorScheme.surface] background, centered brand logo (the
/// full lockup already carries the "RAHETI" wordmark, so no separate app
/// name text is rendered alongside it), and an indeterminate loading
/// indicator with an explicit screen-reader announcement (per the
/// wireframe's accessibility note — loading state must be announced, not
/// only shown visually).
///
/// Auto-advances to SCR-003 (Map) after ~2s, per the wireframe's target —
/// wired now that Feature 1 (Map & Discovery) exists; SCR-002 (onboarding)
/// is not implemented yet, so this always routes to Map, not conditionally
/// to onboarding on first launch (a future refinement, not scoped to
/// US-01.1.1).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _autoAdvanceTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) context.go(AppRoutePaths.map);
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    // Responsive: a fraction of screen width, clamped so the lockup stays
    // legible on small phones and doesn't dominate tablet/landscape layouts.
    final double logoSize = (MediaQuery.sizeOf(context).width * 0.5).clamp(
      160.0,
      280.0,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Spacer(flex: 2),
            Semantics(
              label: l10n.splashSemanticLabel,
              child: ExcludeSemantics(
                child: BrandLogo(
                  variant: BrandLogoVariant.full,
                  size: logoSize,
                ),
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: RahatiSpacing.space8),
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
