/// 8dp-grid spacing tokens, ported 1:1 from `packages/design-tokens/spacing.json`.
///
/// Source of truth: docs/design/foundations.md §6. `space1` (4dp) is the
/// only permitted half-step below the 8dp rhythm — reserved for icon/label
/// micro-alignment, never macro layout spacing.
abstract final class RahatiSpacing {
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;
}
