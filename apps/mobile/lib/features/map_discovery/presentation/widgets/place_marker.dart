import "package:flutter/material.dart";

import "../../../../core/theme/color_tokens.dart";
import "../../domain/entities/place.dart";

/// A single map pin for a [Place], colored per the RAH-DOC-002 §4.2
/// functional-color coding (green=free WC, blue=paid WC, amber=RAHETI
/// unit, magenta=Slatoki) — FR-MAP-02. Reads its color from
/// [RahatiFunctionalColors], never a hard-coded [Color], per ADR-0011.
///
/// **Icon is derived from [Place.pinColor] (4-way), not [Place.placeKind]
/// (2-way)** — `Icons.wc` (free), `Icons.payments_outlined` (paid),
/// `Icons.verified_outlined` (RAHETI unit), `Icons.mosque` (Slatoki). This
/// gives every one of the 4 functional-color categories its own glyph,
/// redundant with (not replacing) color — colors are unchanged. Before
/// this fix, the icon was chosen from `placeKind` (station/thirdPartyPlace,
/// only 2 values), so within a `placeKind` the two `pinColor` values it can
/// take (e.g. a plain RAHETI unit vs. one with a Slatoki space, both
/// `station`) rendered an *identical* icon, differing only by hue — a
/// WCAG 2.2 SC 1.4.1 (Use of Color) violation confirmed against this app's
/// own fixture data and fixed as part of the US-06.4 accessibility audit
/// (finding F10).
///
/// Tapping a pin (FR-MAP-03, place detail sheet) is a separate story
/// (US-01.2.x) — this widget is display-only for now; `onTap` is wired to a
/// no-op-safe callback so the seam exists without inventing a destination
/// screen that doesn't exist yet.
class PlaceMarker extends StatelessWidget {
  const PlaceMarker({required this.place, this.onTap, super.key});

  final Place place;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final RahatiFunctionalColors colors = Theme.of(
      context,
    ).extension<RahatiFunctionalColors>()!;
    final (Color background, Color foreground) = switch (place.pinColor) {
      PinColor.green => (colors.success, colors.onSuccess),
      PinColor.blue => (colors.info, colors.onInfo),
      PinColor.amber => (colors.rahatiUnit, colors.onRahatiUnit),
      PinColor.magenta => (colors.slatoki, colors.onSlatoki),
    };

    return Semantics(
      label: place.name.forLanguageCode(
        Localizations.localeOf(context).languageCode,
      ),
      button: true,
      // GestureDetector wraps a 48×48dp SizedBox, not the 32×32dp visual
      // pin directly, to meet the project's 48×48dp minimum touch target
      // "regardless of visual size" (docs/design/component-library.md) —
      // found during the US-06.4 accessibility audit.
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                // `Colors.white` is intentional here, not a token-discipline
                // gap (US-06.4 finding, resolved as reviewed-not-a-defect):
                // this halo must stay legible against the raster map tile
                // imagery underneath, which never follows the app's own
                // light/dark theme — the same "generic UI chrome, not a
                // status color" carve-out ClusterMarker's own doc comment
                // already states for itself.
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    // Token-sourced, not a hard-coded literal (US-06.4
                    // finding) — byte-identical to the old `Colors.black26`
                    // since `colorScheme.shadow` is pure black in both
                    // themes, so this is a pure discipline fix with no
                    // visual change.
                    color: colorScheme.shadow.withAlpha(0x42),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                switch (place.pinColor) {
                  PinColor.green => Icons.wc,
                  PinColor.blue => Icons.payments_outlined,
                  PinColor.amber => Icons.verified_outlined,
                  PinColor.magenta => Icons.mosque,
                },
                size: 18,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
