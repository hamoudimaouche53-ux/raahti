import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../providers/qibla_providers.dart";
import "../widgets/qibla_compass.dart";

/// SCR-009 — Qibla Full-Screen (US-02.1.2), pushed from [QiblaCompass]'s
/// compact card on SCR-008. Full-screen, minimal chrome per the wireframe:
/// a back-only Top App Bar, the large 240dp compass, and — as separate
/// screen elements below it, not inside the compass widget itself — the
/// numeric degree readout and the calibration hint.
class QiblaFullScreen extends ConsumerWidget {
  const QiblaFullScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final bool available = ref.watch(compassAvailableProvider);
    final double? bearing = ref.watch(qiblaBearingProvider).value;
    final double? accuracy = ref.watch(compassEventProvider).value?.accuracy;
    final bool calibrating =
        accuracy == null || accuracy > QiblaCompass.calibrationThresholdDegrees;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RahatiSpacing.space6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const QiblaCompass(mode: QiblaCompassMode.full),
                const SizedBox(height: RahatiSpacing.space6),
                if (!available)
                  Container(
                    padding: const EdgeInsets.all(RahatiSpacing.space4),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.qiblaUnavailableBanner,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else ...<Widget>[
                  if (bearing != null)
                    Text(
                      "${bearing.round()}° — ${l10n.qiblaMeccaLabel}",
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  if (calibrating) ...<Widget>[
                    const SizedBox(height: RahatiSpacing.space2),
                    Text(
                      l10n.qiblaCalibratingHint,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
