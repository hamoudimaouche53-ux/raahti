import "package:flutter/material.dart";

/// Enforces the project's 48dp minimum touch target inside a
/// [SimpleDialogOption], which — unlike `ListTile`/`FilledButton` — has no
/// built-in tap-target floor (docs/design/component-library.md; found
/// during the US-06.4 accessibility audit, finding F7/F8). Extracted from
/// `SavedPaymentMethodsScreen`'s original private `_DialogOptionTapTarget`
/// when `PaymentMethodSelectionSheet`'s own "add payment method" dialog
/// (the same `SimpleDialogOption` pattern, a separate finding — F8) became
/// this widget's second use site.
class DialogOptionTapTarget extends StatelessWidget {
  const DialogOptionTapTarget({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text),
      ),
    );
  }
}
