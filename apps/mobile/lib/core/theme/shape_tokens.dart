import "package:flutter/material.dart";

/// Corner-radius tokens, ported 1:1 from `packages/design-tokens/shape.json`.
///
/// Source of truth: docs/design/foundations.md §7.
abstract final class RahatiShape {
  static const double none = 0;
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 28;
  static const double full = 9999;

  static const BorderRadius extraSmallRadius = BorderRadius.all(
    Radius.circular(extraSmall),
  );
  static const BorderRadius smallRadius = BorderRadius.all(
    Radius.circular(small),
  );
  static const BorderRadius mediumRadius = BorderRadius.all(
    Radius.circular(medium),
  );
  static const BorderRadius largeRadius = BorderRadius.all(
    Radius.circular(large),
  );
  static const BorderRadius extraLargeRadius = BorderRadius.all(
    Radius.circular(extraLarge),
  );
  static const BorderRadius fullRadius = BorderRadius.all(
    Radius.circular(full),
  );
}
