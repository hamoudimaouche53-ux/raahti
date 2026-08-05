import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:rahati/core/theme/app_theme.dart";
import "package:rahati/features/access_payment/domain/entities/money.dart";
import "package:rahati/features/profile/domain/entities/visit.dart";
import "package:rahati/features/profile/domain/repositories/visit_history_repository.dart";
import "package:rahati/features/profile/presentation/providers/profile_providers.dart";
import "package:rahati/features/profile/presentation/screens/visit_history_screen.dart";
import "package:rahati/l10n/app_localizations.dart";

class _FakeVisitHistoryRepository implements VisitHistoryRepository {
  const _FakeVisitHistoryRepository(this.visits);
  final List<Visit> visits;

  @override
  Future<List<Visit>> getVisitHistory() async => visits;
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Visit> visits,
  Locale locale = const Locale("fr"),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        visitHistoryRepositoryProvider.overrideWithValue(
          _FakeVisitHistoryRepository(visits),
        ),
      ],
      child: MaterialApp(
        theme: RahatiTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const VisitHistoryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("shows the empty state when there are no visits", (tester) async {
    await _pump(tester, visits: const []);

    expect(find.text("Aucune visite pour le moment"), findsOneWidget);
  });

  testWidgets("shows each visit's place name and amount (or Gratuit)", (
    tester,
  ) async {
    await _pump(
      tester,
      visits: [
        Visit(
          id: "v1",
          placeName: "Station Didouche",
          occurredAt: DateTime(2026, 8, 2, 9),
          amount: const Money(amount: "50", currency: "DZD"),
        ),
        Visit(
          id: "v2",
          placeName: "Station El Djazair",
          occurredAt: DateTime(2026, 7, 20, 14),
          amount: null,
        ),
      ],
    );

    expect(find.text("Station Didouche"), findsOneWidget);
    expect(find.text("50 DZD"), findsOneWidget);
    expect(find.text("Station El Djazair"), findsOneWidget);
    expect(find.text("Gratuit"), findsOneWidget);
  });

  testWidgets("renders correctly under the Arabic (RTL) locale", (
    tester,
  ) async {
    await _pump(tester, visits: const [], locale: const Locale("ar"));

    expect(find.text("سجل الزيارات"), findsOneWidget);
  });

  testWidgets("the AppBar back button is a real BackButton, carrying Flutter's "
      "automatic localized tooltip instead of an unlabeled custom "
      "IconButton (US-06.4)", (tester) async {
    await _pump(tester, visits: const []);

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
  });
}
