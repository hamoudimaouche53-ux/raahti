import "package:flutter/material.dart";

import "../../../../core/theme/color_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../../map_discovery/domain/entities/slatoki_tent.dart";

/// Component Library §9.2 — the bespoke Slatoki Tent-Status Card (US-02.1.5,
/// FR-SLK-05): a filled `Card` + leading tent glyph (`slatoki` color) +
/// two-line content + a trailing deployment `Chip` (filled `slatoki` when
/// deployed, outlined `onSurfaceVariant` when folded — never color alone:
/// the chip's own text always says "Déployée"/"Repliée").
///
/// [placeName] is the headline (every other list item in this app leads
/// with the place's real name; the component library's literal "deployment
/// status headline" wording is read here as describing the wireframe's
/// compressed single-line ASCII rendering, not as excluding the name).
/// Deployment status is conveyed by the trailing chip instead, matching
/// the component library's own state description for that chip.
class SlatokiTentStatusCard extends StatelessWidget {
  const SlatokiTentStatusCard({
    required this.placeName,
    required this.tent,
    super.key,
    this.onTap,
  });

  final String placeName;
  final SlatokiTent tent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final RahatiFunctionalColors functionalColors = Theme.of(
      context,
    ).extension<RahatiFunctionalColors>()!;
    final bool deployed = tent.deploymentStatus == DeploymentStatus.deployed;

    return Card(
      color: colorScheme.surfaceContainerHigh,
      margin: const EdgeInsets.symmetric(
        horizontal: RahatiSpacing.space4,
        vertical: RahatiSpacing.space1,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.cabin, color: functionalColors.slatoki),
        title: Text(placeName),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.slatokiTentMatCapacity(tent.matCapacity)),
            if (tent.hasLighting) ...<Widget>[
              const Text(" · "),
              Semantics(
                label: l10n.slatokiTentLightingLabel,
                child: const ExcludeSemantics(
                  child: Icon(Icons.lightbulb_outline, size: 18),
                ),
              ),
            ],
            if (tent.hasPrivacyCurtain) ...<Widget>[
              const Text(" · "),
              Semantics(
                label: l10n.slatokiTentPrivacyCurtainLabel,
                child: const ExcludeSemantics(
                  child: Icon(Icons.privacy_tip_outlined, size: 18),
                ),
              ),
            ],
          ],
        ),
        trailing: Chip(
          label: Text(
            deployed ? l10n.slatokiTentDeployed : l10n.slatokiTentFolded,
          ),
          backgroundColor: deployed
              ? functionalColors.slatoki
              : Colors.transparent,
          labelStyle: TextStyle(
            color: deployed
                ? functionalColors.onSlatoki
                : colorScheme.onSurfaceVariant,
          ),
          side: deployed
              ? BorderSide.none
              : BorderSide(color: colorScheme.outline),
        ),
      ),
    );
  }
}
