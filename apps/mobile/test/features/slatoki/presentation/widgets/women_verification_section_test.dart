import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/core/theme/color_tokens.dart";
import "package:rahati/features/slatoki/domain/entities/women_verification_level.dart";
import "package:rahati/features/slatoki/presentation/widgets/women_verification_section.dart";
import "package:rahati/l10n/app_localizations.dart";

Widget _wrap(WomenVerificationLevel level) {
  return MaterialApp(
    theme: RahatiTheme.light,
    locale: const Locale("fr"),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: WomenVerificationSection(level: level)),
  );
}

void main() {
  testWidgets(
    "verifiedConfirmed: shows a filled 'slatoki' Chip with the full label",
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(WomenVerificationLevel.verifiedConfirmed));
      await tester.pump();

      expect(find.text("Femmes — section confirmée"), findsOneWidget);
      final Chip chip = tester.widget<Chip>(find.byType(Chip));
      final BuildContext context = tester.element(find.byType(Chip));
      final RahatiFunctionalColors colors = Theme.of(
        context,
      ).extension<RahatiFunctionalColors>()!;
      expect(chip.backgroundColor, colors.slatoki);
    },
  );

  testWidgets("generic: shows the neutral note, no Chip", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(WomenVerificationLevel.generic));
    await tester.pump();

    expect(find.text("Statut femmes non confirmé"), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
  });
}
