import "package:flutter/material.dart";

/// Which `assets/images/branding/` artwork [BrandLogo] renders.
enum BrandLogoVariant {
  /// Full color mark + "RAHETI" wordmark, transparent background. Default
  /// choice for splash and auth screens over a themed surface color.
  full,

  /// Full color mark only (no wordmark), transparent background. For
  /// space-constrained contexts — AppBar leading slot, launcher icon
  /// source — where the full lockup wouldn't stay legible.
  icon,

  /// Mark + wordmark rendered in solid white, transparent background. For
  /// placement over dark or photographic backgrounds.
  white,

  /// Mark + wordmark rendered in solid black, transparent background. For
  /// placement over light backgrounds where the full-color mark would clash.
  black,
}

/// RAHETI's brand mark. The single call site for `Image.asset` against
/// `assets/images/branding/` — every screen that needs the logo goes
/// through this widget instead of duplicating the asset path.
class BrandLogo extends StatelessWidget {
  const BrandLogo({required this.variant, this.size = 64, super.key});

  final BrandLogoVariant variant;

  /// Side length of the (square) render box; the asset itself is scaled to
  /// fit within it via [BoxFit.contain].
  final double size;

  static const Map<BrandLogoVariant, String> _assetPaths =
      <BrandLogoVariant, String>{
        BrandLogoVariant.full: "assets/images/branding/logo_full.png",
        BrandLogoVariant.icon: "assets/images/branding/logo_icon.png",
        BrandLogoVariant.white: "assets/images/branding/logo_white.png",
        BrandLogoVariant.black: "assets/images/branding/logo_black.png",
      };

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPaths[variant]!,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
