import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/core/theme/color_tokens.dart";
import "package:rahati/features/map_discovery/domain/entities/slatoki_tent.dart";
import "package:rahati/features/slatoki/presentation/widgets/slatoki_tent_status_card.dart";
import "package:rahati/l10n/app_localizations.dart";

Widget _wrap(SlatokiTent tent, {VoidCallback? onTap, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? RahatiTheme.light,
    locale: const Locale("fr"),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: SlatokiTentStatusCard(
        placeName: "Tente RAHETI Didouche",
        tent: tent,
        onTap: onTap,
      ),
    ),
  );
}

const _deployedFullyEquipped = SlatokiTent(
  deploymentStatus: DeploymentStatus.deployed,
  matCapacity: 4,
  hasLighting: true,
  hasPrivacyCurtain: true,
);

const _foldedNoAmenities = SlatokiTent(
  deploymentStatus: DeploymentStatus.folded,
  matCapacity: 0,
  hasLighting: false,
  hasPrivacyCurtain: false,
);

void main() {
  testWidgets("shows the place name", (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(_deployedFullyEquipped));
    await tester.pump();

    expect(find.text("Tente RAHETI Didouche"), findsOneWidget);
  });

  testWidgets("shows the mat capacity", (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(_deployedFullyEquipped));
    await tester.pump();

    expect(find.text("4 tapis"), findsOneWidget);
  });

  testWidgets(
    "deployed: filled 'slatoki' chip labeled 'Déployée', amenity icons shown",
    (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(_deployedFullyEquipped));
      await tester.pump();

      expect(find.text("Déployée"), findsOneWidget);
      final Chip chip = tester.widget<Chip>(find.byType(Chip));
      final BuildContext context = tester.element(find.byType(Chip));
      final RahatiFunctionalColors colors = Theme.of(
        context,
      ).extension<RahatiFunctionalColors>()!;
      expect(chip.backgroundColor, colors.slatoki);
      expect(chip.side, BorderSide.none);

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
    },
  );

  testWidgets("folded: outlined chip labeled 'Repliée', no amenity icons", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_foldedNoAmenities));
    await tester.pump();

    expect(find.text("Repliée"), findsOneWidget);
    final Chip chip = tester.widget<Chip>(find.byType(Chip));
    expect(chip.backgroundColor, Colors.transparent);
    expect(chip.side, isNot(BorderSide.none));

    expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    expect(find.byIcon(Icons.privacy_tip_outlined), findsNothing);
  });

  testWidgets("amenity icons carry a screen-reader label (never icon-only)", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(_deployedFullyEquipped));
    await tester.pump();

    // Substring match, not exact: ListTile merges its subtitle row's
    // Semantics nodes into one combined announcement rather than keeping
    // each icon's label separately addressable.
    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp("Éclairage disponible")),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp("Rideau de confidentialité disponible")),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets("tapping the card invokes onTap", (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      _wrap(_deployedFullyEquipped, onTap: () => tapped = true),
    );
    await tester.pump();

    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });

  testWidgets("renders correctly against the dark theme", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_deployedFullyEquipped, theme: RahatiTheme.dark),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
