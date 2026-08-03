import "package:flutter/material.dart";

/// The user's own live position, per FR-MAP-01. Uses M3's `primary` role
/// (this is app chrome, not a place-status pin — never a functional color).
class UserPositionMarker extends StatelessWidget {
  const UserPositionMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: "Votre position",
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.surface, width: 3),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Colors.black38, blurRadius: 4),
          ],
        ),
      ),
    );
  }
}
