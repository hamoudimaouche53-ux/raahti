import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/access_payment/domain/entities/money.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method_type.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_method_repository.dart";
import "package:rahati/features/access_payment/presentation/providers/payment_providers.dart";
import "package:rahati/features/access_payment/presentation/screens/payment_method_selection_sheet.dart";
import "package:rahati/l10n/app_localizations.dart";

class _FakePaymentMethodRepository implements PaymentMethodRepository {
  _FakePaymentMethodRepository({List<PaymentMethod>? seed})
    : _methods = List<PaymentMethod>.of(seed ?? _defaultSeed());

  static List<PaymentMethod> _defaultSeed() => const [
    PaymentMethod(
      id: "pm-1",
      methodType: PaymentMethodType.card,
      providerRef: "Visa ...4242",
      isDefault: true,
    ),
    PaymentMethod(
      id: "pm-2",
      methodType: PaymentMethodType.mobileWallet,
      providerRef: "Wallet Mobile",
      isDefault: false,
    ),
  ];

  final List<PaymentMethod> _methods;

  @override
  Future<List<PaymentMethod>> getSavedPaymentMethods() async =>
      List<PaymentMethod>.unmodifiable(_methods);

  @override
  Future<PaymentMethod> addPaymentMethod({
    required PaymentMethodType methodType,
    required String providerToken,
  }) async {
    final added = PaymentMethod(
      id: "pm-new",
      methodType: methodType,
      providerRef: "New method",
      isDefault: false,
    );
    _methods.add(added);
    return added;
  }

  @override
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    _methods.removeWhere((m) => m.id == paymentMethodId);
  }

  @override
  Future<PaymentMethod> setDefaultPaymentMethod(
    String paymentMethodId,
  ) async {
    return _methods.first;
  }
}

class _PushResult {
  String? value;
  bool completed = false;
}

Future<_PushResult> _pumpSheet(
  WidgetTester tester, {
  List<PaymentMethod>? seed,
}) async {
  final result = _PushResult();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        paymentMethodRepositoryProvider.overrideWithValue(
          _FakePaymentMethodRepository(seed: seed),
        ),
      ],
      child: MaterialApp(
        theme: RahatiTheme.light,
        locale: const Locale("fr"),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result.value = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const PaymentMethodSelectionSheet(
                  amount: Money(amount: "50", currency: "DZD"),
                ),
              );
              result.completed = true;
            },
            child: const Text("open"),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text("open"));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets("shows saved methods and the total/pay button once loaded", (
    tester,
  ) async {
    await _pumpSheet(tester);

    expect(find.text("Visa ...4242"), findsOneWidget);
    expect(find.text("Wallet Mobile"), findsOneWidget);
    expect(find.text("Ajouter un moyen de paiement"), findsOneWidget);
    expect(find.text("50 DZD"), findsWidgets);
    expect(find.text("Payer 50 DZD"), findsOneWidget);
  });

  testWidgets(
    "pre-selects the default method so the pay button is enabled",
    (tester) async {
      await _pumpSheet(tester);

      final FilledButton payButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, "Payer 50 DZD"),
      );
      expect(payButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    "disables the pay button when there are no saved methods",
    (tester) async {
      await _pumpSheet(tester, seed: const []);

      final FilledButton payButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, "Payer 50 DZD"),
      );
      expect(payButton.onPressed, isNull);
      expect(find.byType(RadioListTile<String>), findsNothing);
    },
  );

  testWidgets("tapping 'Payer' pops with the selected method id", (
    tester,
  ) async {
    final result = await _pumpSheet(tester);

    await tester.tap(find.text("Payer 50 DZD"));
    await tester.pumpAndSettle();

    expect(result.completed, isTrue);
    // Pre-selected the default method (pm-1, Visa) — nothing else tapped.
    expect(result.value, "pm-1");
  });

  testWidgets(
    "selecting a different radio then paying pops with that method's id",
    (tester) async {
      final result = await _pumpSheet(tester);

      await tester.tap(find.text("Wallet Mobile"));
      await tester.pump();
      await tester.tap(find.text("Payer 50 DZD"));
      await tester.pumpAndSettle();

      expect(result.value, "pm-2");
    },
  );

  testWidgets(
    "adding a method via the stand-in dialog selects it and pays with it",
    (tester) async {
      final result = await _pumpSheet(tester, seed: const []);

      await tester.tap(find.text("Ajouter un moyen de paiement"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Carte bancaire"));
      await tester.pumpAndSettle();

      final FilledButton payButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, "Payer 50 DZD"),
      );
      expect(payButton.onPressed, isNotNull);

      await tester.tap(find.text("Payer 50 DZD"));
      await tester.pumpAndSettle();

      expect(result.value, "pm-new");
    },
  );
}
