import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../../core/theme/color_tokens.dart";
import "../../../../core/theme/shape_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../core/widgets/dialog_option_tap_target.dart";
import "../../../../l10n/app_localizations.dart";
import "../../../emergency/presentation/providers/emergency_providers.dart";
import "../../domain/entities/money.dart";
import "../../domain/entities/payment_method.dart";
import "../../domain/entities/payment_method_type.dart";
import "../../domain/services/idempotency_key_generator.dart";
import "../providers/payment_providers.dart";

/// SCR-015 — Payment Method Selection Sheet (US-04.3, FR-PAY-03),
/// presented via `showModalBottomSheet` (a Modal Bottom Sheet per the
/// wireframe, not a routed screen — it never needs to escape the calling
/// screen's Navigator, unlike SCR-013/014's full-screen routes).
///
/// Pops with the selected [PaymentMethod.id] on "Payer", or `null` if the
/// user dismisses the sheet without paying — the caller (`PlaceDetailSheet`)
/// decides what that means (this story treats it as "stay put," no
/// AccessSession is abandoned since it was already created by SCR-014).
class PaymentMethodSelectionSheet extends ConsumerStatefulWidget {
  const PaymentMethodSelectionSheet({required this.amount, super.key});

  final Money amount;

  @override
  ConsumerState<PaymentMethodSelectionSheet> createState() =>
      _PaymentMethodSelectionSheetState();
}

class _PaymentMethodSelectionSheetState
    extends ConsumerState<PaymentMethodSelectionSheet> {
  String? _selectedMethodId;

  /// The real flow routes to an external provider-hosted UI (ADR-0014,
  /// SCR-015's own wireframe note: "provider-owned, not RAHATI-designed")
  /// — out of this app's design authority to build. This dialog is a
  /// minimal stand-in so the mock tokenization path
  /// (`PaymentMethodRepository.addPaymentMethod`) is still exercisable
  /// end-to-end, not merely documented as deferred.
  Future<void> _showAddMethodDialog() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // Each option's child is wrapped in DialogOptionTapTarget, not a bare
    // Text — SimpleDialogOption has no built-in 48dp tap-target floor,
    // unlike ListTile/FilledButton elsewhere in this app (US-06.4 finding
    // F8, the same defect class as F7's identical dialog pattern in
    // SavedPaymentMethodsScreen — see that shared widget's own doc
    // comment).
    final PaymentMethodType? chosen = await showDialog<PaymentMethodType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.paymentMethodAddDialogTitle),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(PaymentMethodType.card),
            child: DialogOptionTapTarget(
              text: l10n.paymentMethodAddDialogCardOption,
            ),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(context).pop(PaymentMethodType.mobileWallet),
            child: DialogOptionTapTarget(
              text: l10n.paymentMethodAddDialogWalletOption,
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: DialogOptionTapTarget(
              text: l10n.paymentMethodAddDialogCancel,
            ),
          ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;

    // A plausible-looking opaque token stand-in — reuses the same RFC
    // 4122 v4 generator the idempotency-key path already relies on,
    // rather than inventing a second ad hoc "fake token" format.
    final String mockProviderToken =
        "mock-token-${const IdempotencyKeyGenerator().generate()}";
    final PaymentMethod added = await ref
        .read(paymentMethodsProvider.notifier)
        .addMethod(methodType: chosen, providerToken: mockProviderToken);
    if (!mounted) return;
    setState(() => _selectedMethodId = added.id);
  }

  IconData _iconFor(PaymentMethodType type) => switch (type) {
    PaymentMethodType.card => Icons.credit_card,
    PaymentMethodType.mobileWallet => Icons.account_balance_wallet_outlined,
    PaymentMethodType.subscription => Icons.subscriptions_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AsyncValue<List<PaymentMethod>> methodsState = ref.watch(
      paymentMethodsProvider,
    );
    // SCR-012 — a **client-side preview only** (ADR-0031: the actual
    // charged amount is authoritatively determined server-side); shown
    // when the session originated from SCR-011 (Mode Urgence) and the
    // TTL-bounded activation flag is still live and eligible.
    final EmergencyActivationState? emergencyActivation = ref.watch(
      effectiveEmergencyActivationProvider,
    );
    final bool showEmergencyDiscountPreview =
        emergencyActivation?.discountEligible ?? false;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: RahatiSpacing.space4,
          right: RahatiSpacing.space4,
          top: RahatiSpacing.space3,
          bottom:
              RahatiSpacing.space4 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: RahatiSpacing.space3),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: RahatiShape.fullRadius,
                ),
              ),
            ),
            Text(
              l10n.paymentMethodSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: RahatiSpacing.space3),
            methodsState.when(
              data: (methods) {
                // First resolve — pre-select the default (or first)
                // method so the pay button isn't needlessly disabled for
                // the common case of an existing saved method.
                if (_selectedMethodId == null && methods.isNotEmpty) {
                  final PaymentMethod preselected = methods.firstWhere(
                    (m) => m.isDefault,
                    orElse: () => methods.first,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _selectedMethodId = preselected.id);
                    }
                  });
                }
                return RadioGroup<String>(
                  groupValue: _selectedMethodId,
                  onChanged: (value) =>
                      setState(() => _selectedMethodId = value),
                  child: Column(
                    children: <Widget>[
                      for (final PaymentMethod method in methods)
                        RadioListTile<String>(
                          value: method.id,
                          title: Text(method.providerRef),
                          secondary: Icon(_iconFor(method.methodType)),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                );
              },
              // US-06.4 finding F23: previously a bare CircularProgressIndicator
              // with no accessible label at all — a screen-reader user got
              // zero indication anything was loading. Now matches the
              // Semantics(liveRegion: true) + message pattern already used
              // correctly by the sibling loading states in
              // cabin_availability_screen.dart / payment_processing_screen.dart.
              loading: () => Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: RahatiSpacing.space6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const CircularProgressIndicator(),
                      const SizedBox(height: RahatiSpacing.space4),
                      Text(
                        l10n.paymentMethodsLoading,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: RahatiSpacing.space4,
                ),
                child: Text(
                  l10n.paymentMethodLoadError,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add),
              title: Text(l10n.paymentMethodAddItem),
              onTap: _showAddMethodDialog,
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  l10n.paymentMethodTotalLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (showEmergencyDiscountPreview)
                  _EmergencyDiscountPricePreview(amount: widget.amount)
                else
                  Text(
                    "${widget.amount.amount} ${widget.amount.currency}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
              ],
            ),
            const SizedBox(height: RahatiSpacing.space3),
            FilledButton(
              // A free cabin (amount "0") needs no saved method to
              // authorize a $0 charge — `PaymentRepository.requestPayment`
              // accepts `paymentMethodId: null` for exactly this case, so
              // the button stays enabled without a selection. Pops ""
              // (not null) in that case — the caller's `paymentMethodId
              // == null` check means "user dismissed," so an intentional
              // free-access confirmation needs a distinguishable value;
              // the caller converts "" back to null before calling
              // `PaymentRepository`.
              onPressed: _selectedMethodId == null && widget.amount.amount != "0"
                  ? null
                  : () => Navigator.of(context).pop(_selectedMethodId ?? ""),
              child: Text(
                l10n.paymentMethodPayButton(
                  "${widget.amount.amount} ${widget.amount.currency}",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SCR-012's price-row treatment: a struck-through original price next to
/// the previewed discounted price, plus a small `successContainer`
/// "Urgence -50%" chip inline. A **preview only** — see this file's own
/// `build()` doc comment above where [showEmergencyDiscountPreview] is
/// computed.
///
/// The struck-through price's accessible alternative is an explicit
/// [Semantics] label (strikethrough styling alone is not accessible) —
/// same `Semantics(label: ..., child: ExcludeSemantics(...))` idiom as
/// `unlock_confirmation_screen.dart`'s success announcement.
class _EmergencyDiscountPricePreview extends StatelessWidget {
  const _EmergencyDiscountPricePreview({required this.amount});

  final Money amount;

  /// Preview-only 50% split — a plain half of [amount], not a
  /// server-confirmed figure. Trims a trailing ".0" for a whole-DZD
  /// amount, the common case, same "amount currency" concatenation
  /// convention this sheet already uses elsewhere (no `intl` currency
  /// formatting exists in this app yet).
  String get _discountedAmountText {
    final double discounted = amount.amountAsDouble * 0.5;
    final String discountedValue = discounted == discounted.roundToDouble()
        ? discounted.toStringAsFixed(0)
        : discounted.toStringAsFixed(2);
    return "$discountedValue ${amount.currency}";
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final RahatiFunctionalColors functionalColors = Theme.of(
      context,
    ).extension<RahatiFunctionalColors>()!;
    final String originalAmountText = "${amount.amount} ${amount.currency}";
    final String discountedAmountText = _discountedAmountText;

    return Semantics(
      label: l10n.paymentMethodEmergencyDiscountAccessibleLabel(
        originalAmountText,
        discountedAmountText,
      ),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              originalAmountText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: RahatiSpacing.space2),
            Text(
              discountedAmountText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: RahatiSpacing.space2),
            Chip(
              label: Text(l10n.paymentMethodEmergencyDiscountChip),
              backgroundColor: functionalColors.successContainer,
              labelStyle: TextStyle(color: functionalColors.onSuccessContainer),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
