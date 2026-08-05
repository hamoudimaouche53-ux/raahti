// Traces to: US-01.1.1 (FR-MAP-01). First dedicated test file for this
// widget — previously only indirectly covered via map_screen_test.dart's
// `find.byType(UserPositionMarker)` existence checks, which never
// exercised the marker's own accessible label.
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/map_discovery/presentation/widgets/user_position_marker.dart";
import "package:rahati/l10n/app_localizations.dart";

Widget _wrap(Widget child, {Locale locale = const Locale("fr")}) {
  return MaterialApp(
    theme: RahatiTheme.light,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
    "exposes a French accessible label under the French locale (US-06.4 "
    "finding F21 — previously a hard-coded French literal regardless of "
    "app locale)",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const UserPositionMarker()));

      expect(find.bySemanticsLabel("Votre position"), findsOneWidget);
      handle.dispose();
    },
  );

  testWidgets(
    "exposes an English accessible label under the English locale, not "
    "the hard-coded French string",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const UserPositionMarker(), locale: const Locale("en")),
      );

      expect(find.bySemanticsLabel("Your position"), findsOneWidget);
      expect(find.bySemanticsLabel("Votre position"), findsNothing);
      handle.dispose();
    },
  );

  testWidgets(
    "exposes an Arabic accessible label under the Arabic locale, not the "
    "hard-coded French string",
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const UserPositionMarker(), locale: const Locale("ar")),
      );

      expect(find.bySemanticsLabel("موقعك"), findsOneWidget);
      expect(find.bySemanticsLabel("Votre position"), findsNothing);
      handle.dispose();
    },
  );
}
