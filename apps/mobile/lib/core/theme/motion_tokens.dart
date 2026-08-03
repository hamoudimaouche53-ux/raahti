import "package:flutter/material.dart";

/// Motion tokens, ported 1:1 from `packages/design-tokens/motion.json`.
///
/// Source of truth: docs/design/foundations.md §5. Easing curves reuse
/// Flutter's built-in M3 [Easing] class (`package:flutter/material.dart`)
/// rather than re-implementing the cubic-bezier values by hand. Note:
/// Foundations §5.2 lists a plain "emphasized" token with the same
/// coefficients as "standard" — the M3 spec's true full "emphasized" curve
/// is a piecewise (non-cubic) curve that Flutter does not expose as a single
/// [Curve]; Flutter instead exposes [Easing.emphasizedAccelerate] /
/// [Easing.emphasizedDecelerate] for enter/exit motion, used directly below.
abstract final class RahatiMotionDuration {
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);
  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);
  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);
  static const Duration long3 = Duration(milliseconds: 550);
  static const Duration long4 = Duration(milliseconds: 600);
  static const Duration extraLong1 = Duration(milliseconds: 700);
  static const Duration extraLong2 = Duration(milliseconds: 800);
  static const Duration extraLong3 = Duration(milliseconds: 900);
  static const Duration extraLong4 = Duration(milliseconds: 1000);
}

abstract final class RahatiMotionEasing {
  static const Curve standard = Easing.standard;
  static const Curve standardDecelerate = Easing.standardDecelerate;
  static const Curve standardAccelerate = Easing.standardAccelerate;
  static const Curve emphasizedDecelerate = Easing.emphasizedDecelerate;
  static const Curve emphasizedAccelerate = Easing.emphasizedAccelerate;
}

/// A [PageTransitionsBuilder] that honors the OS-level "reduce motion"
/// accessibility setting (docs/design/foundations.md §5.3, SRS
/// NFR-A11Y-02 — "a hard requirement, not optional"): when
/// [MediaQuery.disableAnimations] is true, every route transition becomes
/// a simple cross-fade instead of the platform default slide/zoom — the
/// primary source of motion-triggered discomfort for vestibular-disorder
/// users. Delegates to [fallback] unchanged when reduced motion is off.
///
/// Scope note: this covers screen-to-screen route transitions, wired once
/// at the theme level so it applies automatically everywhere per
/// Foundations §5.3's wording. It does not (yet) touch the handful of
/// in-place `AnimationController`s some screens construct directly
/// (qibla_compass.dart's pulse, qr_scanner_screen.dart's pulse/scan-frame
/// animation, map_screen.dart's camera pan, unlock_confirmation_screen.dart's
/// progress sequence) — each of those conveys real state, not decorative
/// motion, and adapting them individually is a larger, screen-by-screen
/// follow-up, flagged here rather than silently claimed as done.
class RahatiReducedMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const RahatiReducedMotionPageTransitionsBuilder(this.fallback);

  final PageTransitionsBuilder fallback;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) {
      return FadeTransition(opacity: animation, child: child);
    }
    return fallback.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
