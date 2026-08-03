import "package:flutter/material.dart";

import "../../../../core/theme/color_tokens.dart";
import "../../domain/entities/place.dart";

/// A single map pin for a [Place], colored per the RAH-DOC-002 §4.2
/// functional-color coding (green=free WC, blue=paid WC, amber=RAHETI
/// unit, magenta=Slatoki) — FR-MAP-02. Reads its color from
/// [RahatiFunctionalColors], never a hard-coded [Color], per ADR-0011.
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
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                switch (place.placeKind) {
                  PlaceKind.station => Icons.wc,
                  PlaceKind.thirdPartyPlace => Icons.place,
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
