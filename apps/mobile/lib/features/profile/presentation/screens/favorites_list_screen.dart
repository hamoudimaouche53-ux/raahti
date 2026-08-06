import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../../core/router/app_router.dart";
import "../../../../l10n/app_localizations.dart";
import "../../../map_discovery/domain/entities/coordinates.dart";
import "../../../map_discovery/domain/entities/favorite.dart";
import "../../../map_discovery/presentation/providers/place_detail_providers.dart";
import "../../../map_discovery/presentation/providers/place_providers.dart";

/// SCR-026 — Favorites List (US-05.4, FR-USR-04).
class FavoritesListScreen extends ConsumerStatefulWidget {
  const FavoritesListScreen({super.key});

  @override
  ConsumerState<FavoritesListScreen> createState() =>
      _FavoritesListScreenState();
}

class _FavoritesListScreenState extends ConsumerState<FavoritesListScreen> {
  Future<List<Favorite>>? _future;

  Future<List<Favorite>> _load() async {
    final String languageCode = Localizations.localeOf(context).languageCode;
    Coordinates? position;
    try {
      position = await ref.read(userPositionProvider.future);
    } catch (_) {
      position = null;
    }
    return ref
        .read(favoriteRepositoryProvider)
        .getFavorites(currentPosition: position, languageCode: languageCode);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _remove(Favorite favorite) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.favoritesRemoveConfirmTitle),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.genericCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.genericDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(favoriteRepositoryProvider).removeFavorite(favorite.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    _future ??= _load();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favoritesTitle),
        leading: BackButton(onPressed: () => context.pop()),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.favoritesSettingsAction,
            onPressed: () =>
                context.push<void>(AppRoutePaths.profileNotificationSettings),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Favorite>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<Favorite> favorites = snapshot.data!;
            if (favorites.isEmpty) {
              return Center(child: Text(l10n.favoritesEmptyState));
            }
            return ListView(
              children: <Widget>[
                for (final Favorite favorite in favorites)
                  ListTile(
                    title: Text(favorite.placeName),
                    subtitle: favorite.distanceMeters == null
                        ? null
                        : Text("${favorite.distanceMeters!.round()} m"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Semantics(
                          // The Switch's own semantics node exposes its
                          // `toggled` state automatically; merging this
                          // label onto it (rather than excluding/replacing
                          // it) is what makes a screen reader read state
                          // and label together ("Me notifier si
                          // disponible, activé"), per the wireframe's own
                          // accessibility requirement.
                          label: l10n.favoritesNotifySwitchLabel,
                          child: Switch(
                            value: favorite.notifyOnAvailable,
                            onChanged: (value) async {
                              await ref
                                  .read(favoriteRepositoryProvider)
                                  .setNotifyOnAvailable(
                                    favoriteId: favorite.id,
                                    notifyOnAvailable: value,
                                  );
                              _reload();
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.genericDeleteButton,
                          onPressed: () => _remove(favorite),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
