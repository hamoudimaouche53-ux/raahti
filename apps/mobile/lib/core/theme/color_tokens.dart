import "package:flutter/material.dart";

/// M3 baseline [ColorScheme]s, ported 1:1 from `packages/design-tokens/color.json`.
///
/// Source of truth: docs/design/foundations.md §1.1. The seed color
/// (`#00677E`) is marked provisional there pending RAH-DOC-002 confirmation
/// — see docs/design/assumptions-and-open-questions.md §2. Do not hand-edit
/// values here without updating color.json first (see
/// packages/design-tokens/README.md governance note).
abstract final class RahatiColorTokens {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF00677E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF9EEEFF),
    onPrimaryContainer: Color(0xFF001F26),
    secondary: Color(0xFF4A6267),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCDE7EC),
    onSecondaryContainer: Color(0xFF051F23),
    tertiary: Color(0xFF52606C),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD5E4F2),
    onTertiaryContainer: Color(0xFF0E1D27),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF5FAFB),
    onSurface: Color(0xFF171D1E),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEFF5F6),
    surfaceContainer: Color(0xFFE9EFF0),
    surfaceContainerHigh: Color(0xFFE3E9EA),
    surfaceContainerHighest: Color(0xFFDDE3E4),
    onSurfaceVariant: Color(0xFF3F484A),
    outline: Color(0xFF6F797A),
    outlineVariant: Color(0xFFBFC8CA),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2B3133),
    onInverseSurface: Color(0xFFECF2F3),
    inversePrimary: Color(0xFF5CD5F5),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF5CD5F5),
    onPrimary: Color(0xFF00363F),
    primaryContainer: Color(0xFF004E5F),
    onPrimaryContainer: Color(0xFF9EEEFF),
    secondary: Color(0xFFB1CBD0),
    onSecondary: Color(0xFF1B3438),
    secondaryContainer: Color(0xFF324B4F),
    onSecondaryContainer: Color(0xFFCDE7EC),
    tertiary: Color(0xFFBAC8D6),
    onTertiary: Color(0xFF243138),
    tertiaryContainer: Color(0xFF3A4750),
    onTertiaryContainer: Color(0xFFD5E4F2),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0E1416),
    onSurface: Color(0xFFDEE3E5),
    surfaceContainerLowest: Color(0xFF090F11),
    surfaceContainerLow: Color(0xFF171D1E),
    surfaceContainer: Color(0xFF1B2122),
    surfaceContainerHigh: Color(0xFF252B2D),
    surfaceContainerHighest: Color(0xFF293032),
    onSurfaceVariant: Color(0xFFBFC8CA),
    outline: Color(0xFF899393),
    outlineVariant: Color(0xFF3F484A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFDEE3E5),
    onInverseSurface: Color(0xFF2B3133),
    inversePrimary: Color(0xFF00677E),
  );
}

/// RAH-DOC-002 §4.2 functional map-pin colors, implemented as an M3
/// [ThemeExtension] per ADR-0011 (extension, never a replacement of the
/// baseline [ColorScheme]). Access via `Theme.of(context).extension<RahatiFunctionalColors>()`.
@immutable
class RahatiFunctionalColors extends ThemeExtension<RahatiFunctionalColors> {
  const RahatiFunctionalColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.rahatiUnit,
    required this.onRahatiUnit,
    required this.rahatiUnitContainer,
    required this.onRahatiUnitContainer,
    required this.slatoki,
    required this.onSlatoki,
    required this.slatokiContainer,
    required this.onSlatokiContainer,
  });

  /// Free WC pin/badge.
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  /// Paid WC pin/badge.
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  /// RAHETI mobile unit pin/badge.
  final Color rahatiUnit;
  final Color onRahatiUnit;
  final Color rahatiUnitContainer;
  final Color onRahatiUnitContainer;

  /// Slatoki pin/badge/accent.
  final Color slatoki;
  final Color onSlatoki;
  final Color slatokiContainer;
  final Color onSlatokiContainer;

  static const RahatiFunctionalColors light = RahatiFunctionalColors(
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFC4EFC4),
    onSuccessContainer: Color(0xFF00210A),
    info: Color(0xFF1565C0),
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFFD3E4FF),
    onInfoContainer: Color(0xFF001C3B),
    rahatiUnit: Color(0xFFB8860B),
    onRahatiUnit: Color(0xFFFFFFFF),
    rahatiUnitContainer: Color(0xFFFFE8A3),
    onRahatiUnitContainer: Color(0xFF271900),
    slatoki: Color(0xFF9C2896),
    onSlatoki: Color(0xFFFFFFFF),
    slatokiContainer: Color(0xFFFFD6F7),
    onSlatokiContainer: Color(0xFF390036),
  );

  static const RahatiFunctionalColors dark = RahatiFunctionalColors(
    success: Color(0xFF8FDB8F),
    onSuccess: Color(0xFF00390D),
    successContainer: Color(0xFF1E5B22),
    onSuccessContainer: Color(0xFFC4EFC4),
    info: Color(0xFFA9C7FF),
    onInfo: Color(0xFF00315C),
    infoContainer: Color(0xFF0F4C9C),
    onInfoContainer: Color(0xFFD3E4FF),
    rahatiUnit: Color(0xFFFFCC5C),
    onRahatiUnit: Color(0xFF402D00),
    rahatiUnitContainer: Color(0xFF8A6300),
    onRahatiUnitContainer: Color(0xFFFFE8A3),
    slatoki: Color(0xFFFFA6F0),
    onSlatoki: Color(0xFF5C0057),
    slatokiContainer: Color(0xFF7A1A75),
    onSlatokiContainer: Color(0xFFFFD6F7),
  );

  @override
  RahatiFunctionalColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? rahatiUnit,
    Color? onRahatiUnit,
    Color? rahatiUnitContainer,
    Color? onRahatiUnitContainer,
    Color? slatoki,
    Color? onSlatoki,
    Color? slatokiContainer,
    Color? onSlatokiContainer,
  }) {
    return RahatiFunctionalColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      rahatiUnit: rahatiUnit ?? this.rahatiUnit,
      onRahatiUnit: onRahatiUnit ?? this.onRahatiUnit,
      rahatiUnitContainer: rahatiUnitContainer ?? this.rahatiUnitContainer,
      onRahatiUnitContainer:
          onRahatiUnitContainer ?? this.onRahatiUnitContainer,
      slatoki: slatoki ?? this.slatoki,
      onSlatoki: onSlatoki ?? this.onSlatoki,
      slatokiContainer: slatokiContainer ?? this.slatokiContainer,
      onSlatokiContainer: onSlatokiContainer ?? this.onSlatokiContainer,
    );
  }

  @override
  RahatiFunctionalColors lerp(
    ThemeExtension<RahatiFunctionalColors>? other,
    double t,
  ) {
    if (other is! RahatiFunctionalColors) return this;
    return RahatiFunctionalColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      rahatiUnit: Color.lerp(rahatiUnit, other.rahatiUnit, t)!,
      onRahatiUnit: Color.lerp(onRahatiUnit, other.onRahatiUnit, t)!,
      rahatiUnitContainer: Color.lerp(
        rahatiUnitContainer,
        other.rahatiUnitContainer,
        t,
      )!,
      onRahatiUnitContainer: Color.lerp(
        onRahatiUnitContainer,
        other.onRahatiUnitContainer,
        t,
      )!,
      slatoki: Color.lerp(slatoki, other.slatoki, t)!,
      onSlatoki: Color.lerp(onSlatoki, other.onSlatoki, t)!,
      slatokiContainer: Color.lerp(
        slatokiContainer,
        other.slatokiContainer,
        t,
      )!,
      onSlatokiContainer: Color.lerp(
        onSlatokiContainer,
        other.onSlatokiContainer,
        t,
      )!,
    );
  }
}
