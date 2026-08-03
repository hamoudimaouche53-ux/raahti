import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_compass/flutter_compass.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/theme/color_tokens.dart";
import "../../../../core/theme/motion_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../providers/qibla_providers.dart";

/// Component Library §9.1 — the bespoke Qibla Compass, composed entirely
/// from M3 primitives (circular [Card]/[Material], [ColorScheme] roles, the
/// `slatoki` functional color) plus a custom-drawn rose/needle (Foundations
/// §2.2's "bespoke, not in Material Symbols" note).
///
/// [QiblaCompassMode.compact] is the 80×80dp SCR-008 home-tab widget card
/// (needle-only, per the component library's "Widget mode" override — no
/// tick marks, no degree label). [QiblaCompassMode.full] is the 240dp
/// SCR-009 centerpiece (rose + tick marks + needle; the numeric degree
/// readout and calibration hint are rendered by [QiblaFullScreen] as
/// separate screen elements below the compass, per that screen's explicit
/// wireframe layout — not duplicated inside this widget).
enum QiblaCompassMode { compact, full }

class QiblaCompass extends ConsumerWidget {
  const QiblaCompass({required this.mode, super.key, this.onTap});

  final QiblaCompassMode mode;
  final VoidCallback? onTap;

  static const double compactSize = 80;
  static const double fullSize = 240;

  /// ADR-0025 — `CompassEvent.accuracy` above this is treated as
  /// "calibrating", not "locked".
  static const double calibrationThresholdDegrees = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double size = mode == QiblaCompassMode.compact
        ? compactSize
        : fullSize;
    final bool available = ref.watch(compassAvailableProvider);

    if (!available) {
      return _CompassCard(
        size: size,
        onTap: onTap,
        semanticLabel: l10n.qiblaUnavailableBanner,
        child: Padding(
          padding: EdgeInsets.all(size * 0.2),
          child: Icon(
            Icons.explore_off_outlined,
            color: colorScheme.onSurfaceVariant,
            size: size * 0.4,
          ),
        ),
      );
    }

    final double? bearing = ref.watch(qiblaBearingProvider).value;
    final CompassEvent? event = ref.watch(compassEventProvider).value;
    final double? heading = event?.heading;
    final double? accuracy = event?.accuracy;
    final bool calibrating =
        bearing == null ||
        heading == null ||
        accuracy == null ||
        accuracy > calibrationThresholdDegrees;
    final double needleAngleDegrees = (bearing != null && heading != null)
        ? ((bearing - heading) % 360 + 360) % 360
        : 0;

    final String semanticLabel =
        mode == QiblaCompassMode.full && bearing != null
        ? l10n.qiblaBearingAnnouncement(
            bearing.round(),
            _cardinalDirectionLabel(l10n, bearing),
          )
        : l10n.qiblaCompactSemanticLabel;

    return _CompassCard(
      size: size,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size(size, size),
            painter: _CompassRosePainter(
              outlineColor: colorScheme.outline,
              showTicks: mode == QiblaCompassMode.full,
            ),
          ),
          _Pulse(
            active: calibrating,
            child: Transform.rotate(
              key: const Key("qiblaNeedleRotation"),
              angle: needleAngleDegrees * math.pi / 180,
              child: CustomPaint(
                size: Size(size * 0.5, size * 0.5),
                painter: _QiblaNeedlePainter(
                  color: Theme.of(
                    context,
                  ).extension<RahatiFunctionalColors>()!.slatoki,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _cardinalDirectionLabel(AppLocalizations l10n, double bearingDegrees) {
  final List<String> labels = <String>[
    l10n.qiblaDirectionN,
    l10n.qiblaDirectionNe,
    l10n.qiblaDirectionE,
    l10n.qiblaDirectionSe,
    l10n.qiblaDirectionS,
    l10n.qiblaDirectionSw,
    l10n.qiblaDirectionW,
    l10n.qiblaDirectionNw,
  ];
  final int index = (((bearingDegrees % 360) + 22.5) / 45).floor() % 8;
  return labels[index];
}

class _CompassCard extends StatelessWidget {
  const _CompassCard({
    required this.size,
    required this.semanticLabel,
    required this.child,
    this.onTap,
  });

  final double size;
  final String semanticLabel;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: ExcludeSemantics(
        child: Material(
          color: colorScheme.surfaceContainerHigh,
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(width: size, height: size, child: child),
          ),
        ),
      ),
    );
  }
}

/// Component Library §9.1 — "needle pulses via `motion` medium-2 opacity
/// loop" while calibrating; steady (no animation running) once locked.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RahatiMotionDuration.medium2,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  ).drive(Tween<double>(begin: 1, end: 0.4));

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Pulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class _CompassRosePainter extends CustomPainter {
  const _CompassRosePainter({
    required this.outlineColor,
    required this.showTicks,
  });

  final Color outlineColor;
  final bool showTicks;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - 4;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (showTicks) {
      final Paint tickPaint = Paint()
        ..color = outlineColor
        ..strokeWidth = 2;
      for (int i = 0; i < 4; i++) {
        final double angle = i * math.pi / 2;
        final Offset direction = Offset(math.sin(angle), -math.cos(angle));
        canvas.drawLine(
          center + direction * (radius - 8),
          center + direction * radius,
          tickPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CompassRosePainter oldDelegate) =>
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.showTicks != showTicks;
}

/// A simple kite-shaped arrow, tip pointing up (0°) before rotation — the
/// "custom needle glyph" Foundations §2.2 calls for, colored via the
/// `slatoki` functional color (Component Library §9.1).
class _QiblaNeedlePainter extends CustomPainter {
  const _QiblaNeedlePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.68, h * 0.55)
      ..lineTo(w / 2, h * 0.42)
      ..lineTo(w * 0.32, h * 0.55)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _QiblaNeedlePainter oldDelegate) =>
      oldDelegate.color != color;
}
