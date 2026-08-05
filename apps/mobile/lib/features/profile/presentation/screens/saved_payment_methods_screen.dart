import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/theme/spacing_tokens.dart";
import "../../../../core/widgets/dialog_option_tap_target.dart";
import "../../../../l10n/app_localizations.dart";
import "../../../access_payment/domain/entities/payment_method.dart";
import "../../../access_payment/domain/entities/payment_method_type.dart";
import "../../../access_payment/domain/repositories/payment_method_repository.dart";
import "../../../access_payment/domain/services/idempotency_key_generator.dart";
import "../../../access_payment/presentation/providers/payment_providers.dart";

IconData _iconFor(PaymentMethodType type) => switch (type) {
  PaymentMethodType.card => Icons.credit_card,
  PaymentMethodType.mobileWallet => Icons.account_balance_wallet_outlined,
  PaymentMethodType.subscription => Icons.subscriptions_outlined,
};

/// SCR-022 — Saved Payment Methods (US-05.2).
///
/// Reuses `access_payment`'s [PaymentMethod]/[PaymentMethodRepository]
/// (Feature 15) rather than a duplicate profile-owned copy — see
/// `PaymentMethodRepository`'s own doc comment. Delete/set-default both
/// throw [PaymentMethodEndpointNotSpecifiedFailure] against the real REST
/// repository (API Contract Gap — no endpoint exists yet); this screen
/// surfaces that as [AppLocalizations.paymentMethodsGapError] rather than
/// a generic error, so it reads as "not built yet," not "broken."
class SavedPaymentMethodsScreen extends ConsumerStatefulWidget {
  const SavedPaymentMethodsScreen({super.key});

  @override
  ConsumerState<SavedPaymentMethodsScreen> createState() =>
      _SavedPaymentMethodsScreenState();
}

class _SavedPaymentMethodsScreenState
    extends ConsumerState<SavedPaymentMethodsScreen> {
  late Future<List<PaymentMethod>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(paymentMethodRepositoryProvider).getSavedPaymentMethods();
  }

  void _reload() {
    setState(() {
      _future = ref
          .read(paymentMethodRepositoryProvider)
          .getSavedPaymentMethods();
    });
  }

  Future<void> _delete(PaymentMethod method) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.paymentMethodsDeleteConfirmTitle),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.genericCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.genericDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(paymentMethodRepositoryProvider)
          .deletePaymentMethod(method.id);
      _reload();
    } on PaymentMethodEndpointNotSpecifiedFailure {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.paymentMethodsGapError)));
    }
  }

  /// Same provider-hosted-checkout stand-in `PaymentMethodSelectionSheet`
  /// already uses (ADR-0014, SCR-015's own wireframe note) — reused here
  /// rather than duplicated, since it's the same underlying action
  /// (`PaymentMethodRepository.addPaymentMethod`) reached from a second
  /// entry point.
  Future<void> _showAddMethodDialog() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PaymentMethodType? chosen = await showDialog<PaymentMethodType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.paymentMethodAddDialogTitle),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () =>
                Navigator.of(context).pop(PaymentMethodType.card),
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

    final String mockProviderToken =
        "mock-token-${const IdempotencyKeyGenerator().generate()}";
    await ref
        .read(paymentMethodRepositoryProvider)
        .addPaymentMethod(methodType: chosen, providerToken: mockProviderToken);
    _reload();
  }

  Future<void> _setDefault(PaymentMethod method) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(paymentMethodRepositoryProvider)
          .setDefaultPaymentMethod(method.id);
      _reload();
    } on PaymentMethodEndpointNotSpecifiedFailure {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.paymentMethodsGapError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentMethodsTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: FutureBuilder<List<PaymentMethod>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<PaymentMethod> methods = snapshot.data!;
            return ListView(
              children: <Widget>[
                if (methods.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(RahatiSpacing.space6),
                    child: Center(child: Text(l10n.paymentMethodsEmptyState)),
                  ),
                for (final PaymentMethod method in methods)
                  ListTile(
                    leading: Icon(_iconFor(method.methodType)),
                    title: Text(method.providerRef),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (method.isDefault)
                          Chip(label: Text(l10n.paymentMethodsDefaultChip))
                        else
                          TextButton(
                            onPressed: () => _setDefault(method),
                            child: Text(l10n.paymentMethodsSetDefaultAction),
                          ),
                        // US-06.4 finding F9 — the Chip/TextButton and the
                        // delete IconButton previously sat flush against
                        // each other with no gap; each nominally meets the
                        // 48dp minimum alone, but with zero spacing their
                        // hit regions abut, risking mis-taps on a real
                        // device.
                        const SizedBox(width: RahatiSpacing.space2),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.genericDeleteButton,
                          onPressed: () => _delete(method),
                        ),
                      ],
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l10n.paymentMethodsAddAction),
                  onTap: _showAddMethodDialog,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
