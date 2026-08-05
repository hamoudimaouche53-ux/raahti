import "dart:async";

import "package:flutter/material.dart";

import "../../../../l10n/app_localizations.dart";

/// SCR-003's floating Search Bar (US-01.1.4, FR-MAP-04) — M3 `SearchBar`
/// pill widget per docs/design/component-library.md §"Search Bar".
///
/// Debounces keystrokes locally (this widget owns the [Timer], not
/// Riverpod state) so [onQueryChanged] — which drives the filtered-places
/// recomputation in `MapScreen` — fires at most once per
/// [debounceDuration] of typing inactivity, not on every keystroke.
class MapSearchBar extends StatefulWidget {
  const MapSearchBar({
    required this.onQueryChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
    super.key,
  });

  final ValueChanged<String> onQueryChanged;
  final Duration debounceDuration;

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onQueryChanged(value);
    });
    // Rebuild immediately so the clear ("x") button's visibility tracks
    // typing without waiting for the debounce — a purely local, cheap
    // setState (this widget only), independent of the debounced callback.
    setState(() {});
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    widget.onQueryChanged("");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // US-06.4 finding F17 flagged SearchBar's `hintText` as "not a
    // reliable accessible name" and proposed wrapping it in an explicit
    // `Semantics(label:)`. Verified during implementation (not assumed):
    // SearchBar composes its own internal `Semantics(inputType:
    // SemanticsInputType.search, child: TextField(decoration:
    // InputDecoration(hintText: ...)))`, and Flutter's own TextField/
    // InputDecorator already correctly exposes `hintText` as a persistent
    // semantics `label` — confirmed by inspecting the Flutter SDK source
    // (`search_anchor.dart`) and, decisively, by a widget test: adding an
    // external `Semantics(label:)` wrapper here produced a genuine
    // *duplicate* announcement (`find.bySemanticsLabel` found 2 matching
    // nodes, one from the wrapper and one already provided internally),
    // both before *and* after text entry — proving the accessible name
    // was already persistent, not tied to the hint's visual disappearance
    // as the original finding assumed. The wrapper was reverted; this is
    // a false positive in the original audit, not a fix that was skipped.
    return SearchBar(
      controller: _controller,
      hintText: l10n.mapSearchHint,
      leading: const Icon(Icons.search),
      trailing: <Widget>[
        if (_controller.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.mapSearchClear,
            onPressed: _clear,
          ),
      ],
      onChanged: _onChanged,
    );
  }
}
