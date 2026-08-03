import "package:flutter_test/flutter_test.dart";
import "package:rahati/features/access_payment/data/repositories/mock_payment_method_repository.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method.dart";
import "package:rahati/features/access_payment/domain/entities/payment_method_type.dart";

void main() {
  group("MockPaymentMethodRepository", () {
    test("getSavedPaymentMethods returns a fabricated default seed", () async {
      final repository = MockPaymentMethodRepository();

      final result = await repository.getSavedPaymentMethods();

      expect(result, hasLength(2));
      expect(result.where((m) => m.isDefault), hasLength(1));
    });

    test("addPaymentMethod makes the new method appear in a subsequent "
        "getSavedPaymentMethods call", () async {
      final repository = MockPaymentMethodRepository();
      final int before = (await repository.getSavedPaymentMethods()).length;

      final added = await repository.addPaymentMethod(
        methodType: PaymentMethodType.card,
        providerToken: "mock-token-1",
      );

      final List<String> ids = (await repository.getSavedPaymentMethods())
          .map((m) => m.id)
          .toList();
      expect(ids, hasLength(before + 1));
      expect(ids, contains(added.id));
    });

    test("deletePaymentMethod removes it from a subsequent list", () async {
      final repository = MockPaymentMethodRepository();
      final first = (await repository.getSavedPaymentMethods()).first;

      await repository.deletePaymentMethod(first.id);

      final after = await repository.getSavedPaymentMethods();
      expect(after.any((m) => m.id == first.id), isFalse);
    });

    test(
      "setDefaultPaymentMethod flips isDefault and unsets every other "
      "method's",
      () async {
        final repository = MockPaymentMethodRepository();
        final List<PaymentMethod> methods = await repository
            .getSavedPaymentMethods();
        final second = methods[1];

        final updated = await repository.setDefaultPaymentMethod(second.id);

        expect(updated.isDefault, isTrue);
        final after = await repository.getSavedPaymentMethods();
        expect(after.where((m) => m.isDefault), hasLength(1));
        expect(after.firstWhere((m) => m.id == second.id).isDefault, isTrue);
      },
    );
  });
}
