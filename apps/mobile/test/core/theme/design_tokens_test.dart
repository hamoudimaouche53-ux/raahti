// Regression guard: these values must stay in sync with
// packages/design-tokens/{spacing,shape,motion}.json — see
// docs/design/foundations.md §5-7. A failing assertion here means either
// the token files changed (update this test) or a Dart constant drifted
// from its JSON source of truth (fix the Dart constant).
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/motion_tokens.dart";
import "package:rahati/core/theme/shape_tokens.dart";
import "package:rahati/core/theme/spacing_tokens.dart";

void main() {
  test("spacing tokens follow the 8dp grid", () {
    expect(RahatiSpacing.space2, 8);
    expect(RahatiSpacing.space4, 16);
    expect(RahatiSpacing.space6, 24);
    expect(RahatiSpacing.space1, lessThan(RahatiSpacing.space2));
  });

  test("shape tokens match the M3 corner-radius scale", () {
    expect(RahatiShape.medium, 12);
    expect(RahatiShape.extraLarge, 28);
    expect(RahatiShape.mediumRadius, BorderRadius.circular(12));
  });

  test("motion duration tokens match the M3 scale", () {
    expect(RahatiMotionDuration.short1, const Duration(milliseconds: 50));
    expect(RahatiMotionDuration.medium1, const Duration(milliseconds: 250));
    expect(RahatiMotionDuration.extraLong4, const Duration(milliseconds: 1000));
  });
}
