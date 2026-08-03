import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "core/providers/app_settings_providers.dart";
import "core/router/app_router.dart";
import "core/theme/app_theme.dart";
import "l10n/app_localizations.dart";

/// Root application widget.
///
/// Wires together the four foundation concerns required by this phase:
/// theme (ADR-0018 / docs/design/foundations.md), localization (ADR-0017,
/// FR/EN/AR with automatic RTL for Arabic), routing ([appRouterProvider]),
/// and state management (Riverpod providers consumed via [ConsumerWidget]).
class RahatiApp extends ConsumerWidget {
  const RahatiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale? localeOverride = ref.watch(localeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: RahatiTheme.light,
      darkTheme: RahatiTheme.dark,
      themeMode: themeMode,
      locale: localeOverride,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      // Swaps to the Arabic typeface pairing once the *resolved* locale
      // (explicit override or system default) is known — see
      // RahatiTheme.resolveForLocale.
      builder: (context, child) {
        final Locale resolvedLocale = Localizations.localeOf(context);
        final ThemeData resolvedTheme = RahatiTheme.resolveForLocale(
          Theme.of(context),
          resolvedLocale,
        );
        return Theme(data: resolvedTheme, child: child!);
      },
    );
  }
}
