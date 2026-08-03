import "package:flutter/material.dart";

/// Minimal geometric logo mark, shared by every screen that needs
/// RAHATI's brand identity (SCR-001 Splash, SCR-030 Sign In/Sign Up). A
/// production brand asset (SVG/image) is a Phase 2 design-system
/// asset-production follow-up — see
/// docs/design/assumptions-and-open-questions.md; this placeholder mark is
/// a real, rendered, themed widget (not a stub), just not the final brand
/// artwork. Extracted from `SplashScreen`'s original private
/// `_RahatiLogoMark` when SCR-030 became this widget's second use site.
class RahatiLogoMark extends StatelessWidget {
  const RahatiLogoMark({
    required this.color,
    required this.onColor,
    this.size = 64,
    super.key,
  });

  final Color color;

  /// The "R" glyph's color — must be the theme's own paired `on*` color for
  /// [color] (e.g. `colorScheme.onPrimary` for `colorScheme.primary`), not
  /// a hard-coded literal. A fixed white glyph fails WCAG 2.2 AA contrast
  /// in dark theme, where `colorScheme.primary` is a light cyan
  /// (`#5CD5F5`) rather than the dark teal used in light theme — flagged
  /// and fixed as part of the US-06.4 accessibility audit.
  final Color onColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        "R",
        style: TextStyle(
          color: onColor,
          fontSize: size * 0.4375,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
