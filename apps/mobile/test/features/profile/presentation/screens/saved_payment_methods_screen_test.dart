import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/core/theme/spacing_tokens.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method_type.dart";
import "package:rahati/features/access_payment/domain/repositories/payment_method_repository.dart";
import "package:rahati/features/access_payment/presentation/providers/payment_providers.dart";
import "package:rahati/features/profile/presentation/screens/saved_payment_methods_screen.dart";
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
    throw const PaymentMethodEndpointNotSpecifiedFailure();
  }
}

Future<void> _pump(
  WidgetTester tester, {
  List<PaymentMethod>? seed,
  Locale locale = const Locale("fr"),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        paymentMethodRepositoryProvider.overrideWithValue(
          _FakePaymentMethodRepository(seed: seed),
        ),
      ],
      child: MaterialApp(
        theme: RahatiTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const SavedPaymentMethodsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("shows the empty state when there are no saved methods", (
    tester,
  ) async {
    await _pump(tester, seed: const []);

    expect(find.text("Aucun moyen de paiement enregistré"), findsOneWidget);
  });

  testWidgets(
    "shows each method's masked identifier and a 'Par défaut' chip on "
    "the default one",
    (tester) async {
      await _pump(tester);

      expect(find.text("Visa ...4242"), findsOneWidget);
      expect(find.text("Wallet Mobile"), findsOneWidget);
      expect(find.text("Par défaut"), findsOneWidget);
      expect(find.text("Définir par défaut"), findsOneWidget);
    },
  );

  testWidgets(
    "deleting a method (after confirming) removes it from the list",
    (tester) async {
      await _pump(tester);

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      expect(find.text("Supprimer ce moyen de paiement ?"), findsOneWidget);

      await tester.tap(find.text("Supprimer"));
      await tester.pumpAndSettle();

      expect(find.text("Visa ...4242"), findsNothing);
      expect(find.text("Wallet Mobile"), findsOneWidget);
    },
  );

  testWidgets(
    "setDefault against the API-contract-gap repository shows the "
    "gap error Snackbar",
    (tester) async {
      await _pump(tester);

      await tester.tap(find.text("Définir par défaut"));
      await tester.pumpAndSettle();

      expect(find.text("Cette action n'est pas encore disponible."), findsOneWidget);
    },
  );

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pump(tester, locale: const Locale("ar"));

    expect(find.text("وسائل الدفع"), findsOneWidget);
  });

  testWidgets(
    "the delete icon button has an accessible tooltip, not just a bare "
    "icon (US-06.4)",
    (tester) async {
      await _pump(tester);

      expect(find.byTooltip("Supprimer"), findsWidgets);
    },
  );

  testWidgets(
    "the AppBar back button is a real BackButton, carrying Flutter's "
    "automatic localized tooltip instead of an unlabeled custom "
    "IconButton (US-06.4)",
    (tester) async {
      await _pump(tester);

      expect(find.byType(BackButton), findsOneWidget);
      final Tooltip tooltip = tester.widget<Tooltip>(
        find
            .descendant(
              of: find.byType(BackButton),
              matching: find.byType(Tooltip),
            )
            .first,
      );
      expect(tooltip.message, isNotEmpty);
    },
  );

  testWidgets(
    "the default-method Chip and the delete IconButton have an explicit "
    "gap between them, not flush edges (US-06.4 finding F9)",
    (tester) async {
      await _pump(tester);

      final Rect chipRect = tester.getRect(find.byType(Chip));
      final Rect deleteRect = tester.getRect(
        find
            .ancestor(
              of: find.byIcon(Icons.delete_outline).first,
              matching: find.byType(IconButton),
            )
            .first,
      );

      expect(
        deleteRect.left - chipRect.right,
        greaterThanOrEqualTo(RahatiSpacing.space2),
        reason: "the default-method Chip and the delete IconButton must "
            "not sit flush against each other, or their hit regions risk "
            "overlapping on a real device even though each nominally "
            "meets the 48dp minimum alone",
      );
    },
  );

  testWidgets(
    "the 'Définir par défaut' TextButton and the delete IconButton have "
    "an explicit gap between them, not flush edges (US-06.4 finding F9)",
    (tester) async {
      await _pump(tester);

      final Rect textButtonRect = tester.getRect(
        find
            .ancestor(
              of: find.text("Définir par défaut"),
              matching: find.byType(TextButton),
            )
            .first,
      );
      final Rect deleteRect = tester.getRect(
        find
            .ancestor(
              of: find.byIcon(Icons.delete_outline).last,
              matching: find.byType(IconButton),
            )
            .first,
      );

      expect(
        deleteRect.left - textButtonRect.right,
        greaterThanOrEqualTo(RahatiSpacing.space2),
        reason: "the 'Définir par défaut' TextButton and the delete "
            "IconButton must not sit flush against each other, or their "
            "hit regions risk overlapping on a real device even though "
            "each nominally meets the 48dp minimum alone",
      );
    },
  );

  testWidgets(
    "each 'add payment method' dialog option meets the 48dp minimum "
    "touch target, unlike SimpleDialogOption's unpadded default "
    "(US-06.4)",
    (tester) async {
      await _pump(tester);

      await tester.tap(find.text("Ajouter un moyen de paiement"));
      await tester.pumpAndSettle();

      final Iterable<Element> options = find
          .byType(SimpleDialogOption)
          .evaluate();
      expect(options, isNotEmpty);
      for (final Element option in options) {
        final Size size = (option.renderObject! as RenderBox).size;
        expect(
          size.height,
          greaterThanOrEqualTo(48),
          reason: "SimpleDialogOption '${option.widget}' is ${size.height}dp"
              " tall, under the 48dp minimum touch target",
        );
      }
    },
  );
}
