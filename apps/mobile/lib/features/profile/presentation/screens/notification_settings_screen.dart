import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../../../../l10n/app_localizations.dart";

/// SCR-027 — Notification Settings (US-05.4, FR-USR-04).
///
/// No `NotificationSettingsRepository` exists — there's no
/// notification-preferences endpoint anywhere in
/// docs/api/openapi.yaml (the closest is `/users/me/notifications`,
/// which is the *inbox* — SCR-028/EPIC-10 — not a settings resource).
/// These three toggles are therefore local `State` only, not persisted —
/// flagged here rather than invented a backend call against a
/// non-existent endpoint. "Actualités RAHETI" defaults to off, per the
/// wireframe (marketing-adjacent).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _favoritesAvailability = true;
  bool _paymentAlerts = true;
  bool _news = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationSettingsTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            SwitchListTile(
              title: Text(l10n.notificationSettingsFavoritesLabel),
              value: _favoritesAvailability,
              onChanged: (value) =>
                  setState(() => _favoritesAvailability = value),
            ),
            SwitchListTile(
              title: Text(l10n.notificationSettingsPaymentAlertsLabel),
              value: _paymentAlerts,
              onChanged: (value) => setState(() => _paymentAlerts = value),
            ),
            SwitchListTile(
              title: Text(l10n.notificationSettingsNewsLabel),
              value: _news,
              onChanged: (value) => setState(() => _news = value),
            ),
          ],
        ),
      ),
    );
  }
}
