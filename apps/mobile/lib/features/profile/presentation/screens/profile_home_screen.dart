import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/router/app_router.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/app_user.dart";
import "../../domain/entities/diabetic_verification_status.dart";
import "../providers/auth_providers.dart";

/// SCR-020 — Profile / Account Home (US-05.1, US-05.2, FLAGSHIP).
///
/// Guest state (no [AppUser]) shows every account-bound section
/// locked-but-visible (never hidden) plus a persistent "Se connecter"
/// button, per the wireframe's own "optional, not required" framing
/// (FR-USR-01). Registered state additionally locks "Statut diabétique
/// vérifié" specifically — US-05.3 (SCR-024/025) is deferred to V1.1 per
/// the Release Alignment table, same "flag not hide" discipline
/// ADR-0024 already applied to the Emergency/Profile nav tabs — and
/// "Notifications" (SCR-028/EPIC-10, not built yet; no notification-inbox
/// endpoint exists). "Langue et thème" (SCR-029/EPIC-06) is unlocked
/// regardless of guest/registered state — language and theme are
/// device-level preferences, not account-bound, so there is nothing to
/// gate behind sign-in.
class ProfileHomeScreen extends ConsumerWidget {
  const ProfileHomeScreen({super.key});

  void _showLocked(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.profileLockedSnackbar)));
  }

  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.profileComingSoonSnackbar)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<AppUser?> userState = ref.watch(currentUserProvider);
    final AppUser? user = userState.value;
    final bool isGuest = user == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileHomeTitle),
        actions: isGuest
            ? null
            : <Widget>[
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: l10n.profileSignOutButton,
                  onPressed: () =>
                      ref.read(authRepositoryProvider).signOut(),
                ),
              ],
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(RahatiSpacing.space6),
              child: _AccountSummaryCard(user: user),
            ),
            if (isGuest)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RahatiSpacing.space6,
                ),
                child: FilledButton(
                  onPressed: () =>
                      context.push<void>(AppRoutePaths.profileSignIn),
                  child: Text(l10n.profileSignInButton),
                ),
              ),
            const SizedBox(height: RahatiSpacing.space4),
            _ProfileListItem(
              icon: Icons.history,
              label: l10n.profileVisitHistoryItem,
              locked: isGuest,
              hint: isGuest ? l10n.profileLockedSnackbar : null,
              onTap: isGuest
                  ? () => _showLocked(context, l10n)
                  : () => context.push<void>(AppRoutePaths.profileVisitHistory),
            ),
            _ProfileListItem(
              icon: Icons.payment,
              label: l10n.profilePaymentMethodsItem,
              locked: isGuest,
              hint: isGuest ? l10n.profileLockedSnackbar : null,
              onTap: isGuest
                  ? () => _showLocked(context, l10n)
                  : () =>
                        context.push<void>(AppRoutePaths.profilePaymentMethods),
            ),
            _ProfileListItem(
              icon: Icons.reviews,
              label: l10n.profileMyReviewsItem,
              locked: isGuest,
              hint: isGuest ? l10n.profileLockedSnackbar : null,
              onTap: isGuest
                  ? () => _showLocked(context, l10n)
                  : () => context.push<void>(AppRoutePaths.profileMyReviews),
            ),
            _ProfileListItem(
              icon: Icons.verified_user,
              label: l10n.profileDiabeticStatusItem,
              locked: true,
              // Always "coming soon" (US-05.3 deferred to V1.1), never
              // sign-in-gated — even a registered, verified user hits this
              // same hint, so it must not reuse profileLockedSnackbar
              // ("Connexion requise"), which would be actively misleading.
              hint: l10n.profileComingSoonSnackbar,
              onTap: () => _showComingSoon(context, l10n),
              trailingBadge:
                  user?.diabeticVerificationStatus ==
                      DiabeticVerificationStatus.verified
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                      semanticLabel: l10n.profileVerifiedDiabeticBadge,
                    )
                  : null,
            ),
            _ProfileListItem(
              icon: Icons.favorite_border,
              label: l10n.profileFavoritesItem,
              locked: isGuest,
              hint: isGuest ? l10n.profileLockedSnackbar : null,
              onTap: isGuest
                  ? () => _showLocked(context, l10n)
                  : () => context.push<void>(AppRoutePaths.profileFavorites),
            ),
            _ProfileListItem(
              icon: Icons.notifications_none,
              label: l10n.profileNotificationsItem,
              locked: true,
              // Same "always coming soon" reasoning as the diabetic-status
              // row above — not sign-in-gated.
              hint: l10n.profileComingSoonSnackbar,
              onTap: () => _showComingSoon(context, l10n),
            ),
            _ProfileListItem(
              icon: Icons.language,
              label: l10n.profileLanguageThemeItem,
              locked: false,
              onTap: () =>
                  context.push<void>(AppRoutePaths.profileLanguageTheme),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  const _AccountSummaryCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String identity = user?.email ?? user?.phone ?? l10n.profileGuestLabel;
    final String initial = user == null ? "?" : identity[0].toUpperCase();
    final bool verified =
        user?.diabeticVerificationStatus ==
        DiabeticVerificationStatus.verified;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(RahatiSpacing.space4),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: RahatiSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(identity, style: Theme.of(context).textTheme.titleMedium),
                  if (verified) ...<Widget>[
                    const SizedBox(height: RahatiSpacing.space1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: RahatiSpacing.space1),
                        Text(
                          l10n.profileVerifiedDiabeticBadge,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single SCR-020 list row. [locked] shows a lock affordance instead of
/// a chevron and — per the wireframe's accessibility requirement —
/// announces *why* the row doesn't behave like a normal navigation item
/// (via [hint]) rather than silently doing nothing on tap; the row stays
/// tappable either way ([onTap] always fires), never `disabled`-and-inert.
class _ProfileListItem extends StatelessWidget {
  const _ProfileListItem({
    required this.icon,
    required this.label,
    required this.locked,
    required this.onTap,
    this.hint,
    this.trailingBadge,
  });

  final IconData icon;
  final String label;
  final bool locked;
  final VoidCallback onTap;

  /// Announced to screen readers *before* activation (a [Semantics] hint,
  /// not just the Snackbar shown after a tap) — a screen-reader user
  /// exploring the list otherwise gets no indication of why the row
  /// doesn't behave like a normal navigation item until after they've
  /// already activated it (found during the US-06.4 accessibility audit).
  /// Passed explicitly per call site rather than derived from [locked]
  /// alone, since "locked" means different things for different rows
  /// (sign-in-required vs. always-coming-soon) and a wrong hint would be
  /// actively misleading, not just missing.
  final String? hint;
  final Widget? trailingBadge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      hint: hint,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ?trailingBadge,
            const SizedBox(width: RahatiSpacing.space1),
            Icon(locked ? Icons.lock_outline : Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
