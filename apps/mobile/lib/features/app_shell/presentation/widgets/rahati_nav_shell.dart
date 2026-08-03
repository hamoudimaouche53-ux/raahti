import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../l10n/app_localizations.dart";

/// Outer `Scaffold` hosting the 4-destination bottom navigation bar
/// (docs/design/component-library.md §5) around a [StatefulNavigationShell]
/// branch. Introduced by US-02.1.1 — see ADR-0024 for why the full 4-tab
/// shape exists from day one even though the Emergency/Profile branches
/// currently render placeholder screens.
///
/// Destination order is pinned left-to-right (Map, Slatoki, Emergency,
/// Profile) in both LTR and RTL locales, per the component library's
/// explicit "order does not reverse" rule (bottom-nav order is fixed by
/// information hierarchy, not mirrored) — achieved by fixing the bar's own
/// layout direction. Each destination's own label still renders its native
/// script/glyphs correctly (Arabic shaping is a property of the text run,
/// not the paragraph base direction), and the M3 `NavigationDestination`
/// centers icon+label regardless of ambient direction, so no content is
/// actually mirrored incorrectly.
class RahatiNavShell extends StatelessWidget {
  const RahatiNavShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.ltr,
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (int index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map),
              label: l10n.navMap,
            ),
            NavigationDestination(
              icon: const Icon(Icons.mosque_outlined),
              selectedIcon: const Icon(Icons.mosque),
              label: l10n.navSlatoki,
            ),
            NavigationDestination(
              icon: const Icon(Icons.emergency_outlined),
              selectedIcon: const Icon(Icons.emergency),
              label: l10n.navEmergency,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
