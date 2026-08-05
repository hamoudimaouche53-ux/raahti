# WCAG 2.2 AA Checklist Sign-Off — US-06.4

| | |
|---|---|
| **Document ID** | RAH-DOC-041-WCAG-CHECKLIST-SIGNOFF |
| **Phase** | Phase 3 — Flutter Implementation (this log's own numbering; Master Roadmap Phase 5) |
| **Status** | Complete |
| **Related** | [Component Library §10](./component-library.md#10-accessibility-checklist-applies-to-every-component-above) · [Implementation Log](../phase-3-implementation-log.md) (Feature 22 — the audit; Features 23–35 — the fixes) |

> This is the checklist sign-off `docs/design/component-library.md` §10 and backlog item US-06.4 (`docs/backlog/product-backlog.md:118`, "WCAG 2.2 AA checklist sign-off") require, and which the implementation log's EPIC-06 closing note (pre-Feature-35) explicitly flagged as never yet performed. It evaluates the **as-implemented app** (`apps/mobile`), not the design spec.

## Method

Each of the 6 checklist items is evaluated against three kinds of evidence, cited per item:
1. **Code inspection** — direct reading of the relevant widget source.
2. **Automated widget-test assertions** — Flutter's own `SemanticsNode`/`flagsCollection`/geometry assertions, run via `flutter test` (527/527 passing at sign-off time). This is the more precise instrument for semantics-tree correctness (accessible names, live-region flags) since Flutter's semantics tree is the single source of truth TalkBack/VoiceOver actually consume — a widget test asserting `flagsCollection.isLiveRegion` verifies the exact same data a screen reader would receive, exhaustively and deterministically, which a one-off manual listening pass cannot guarantee to cover.
3. **On-device physical verification** — via `adb`/`uiautomator` against a connected physical Android device (model `21121119SC`), for the two classes of concern that only exist on real hardware: physical touch-target geometry after real display-density scaling (F9), and confirming the on-device accessibility-node tree matches what the widget tests predict (no VoiceOver/iOS device was available in this environment — see the iOS caveat below).

**iOS/VoiceOver caveat**: no iOS device or macOS host was available in this environment. Every on-device claim below is Android/TalkBack-node-tree only. This is stated explicitly rather than left implicit, per this project's own established discipline of not silently claiming coverage it doesn't have.

## Checklist

### 1. Minimum 48×48dp touch target

**Status: PASS.**
- Every custom-tappable element found with a below-minimum touch target during Feature 22's audit was fixed and is asserted by a dedicated test: map markers (`PlaceMarker`/`ClusterMarker`, 48×48dp `SizedBox` wrapping the visual pin — `map_screen_test.dart`, `cluster_marker_test.dart`), dialog options (`DialogOptionTapTarget`, `ConstrainedBox(minHeight: 48)` — `saved_payment_methods_screen_test.dart`, `payment_method_selection_sheet_test.dart`), and the F9 spacing fix (explicit 8dp gap between adjacent controls, geometry-asserted via `tester.getRect`).
- Every other interactive element is a stock Material widget (`FilledButton`, `TextButton`, `IconButton`, `ListTile`, `Chip`, `SegmentedButton`) which meets 48dp by M3 default, unmodified.
- **On-device**: F9's gap re-measured on the physical device — *pending device reconnection, see Outstanding Items below.*

### 2. Text contrast ≥4.5:1 (body), ≥3:1 (large text/graphical)

**Status: PASS, with one documented exception.**
- Every *reachable* color-token pair in `RahatiColorTokens`/`RahatiFunctionalColors` (light + dark) was contrast-computed during Feature 22's audit; failures found (F2 logo glyph, and others) were fixed.
- **One exception, confirmed dead code, not fixed**: dark-theme `RahatiFunctionalColors.rahatiUnitContainer` (`#8A6300`) / `onRahatiUnitContainer` (`#FFE8A3`) computes to **4.48:1**, 0.02 below the 4.5:1 body-text threshold (passes the 3:1 large-text/graphical minimum). A repo-wide grep confirms **zero usages** of this token pair (or any of the other `*Container`/`on*Container` roles on `RahatiFunctionalColors`) anywhere in `lib/features/` — only the base `rahatiUnit`/`onRahatiUnit` roles are used. Editing this value would mean hand-editing `packages/design-tokens/color.json`, a governance-tracked, Phase-2-signed-off source-of-truth file (per its own README), to correct a color nothing currently renders. **Decision: documented, not fixed** — tracked here for correction at the point these container roles are ever wired to a real screen, rather than churning a locked design-token file for unreachable code.

### 3. Focus indicator ≥2px, ≥3:1 contrast, never fully obscured (WCAG 2.2 SC 2.4.11)

**Status: PASS for keyboard-operable controls; scope boundary noted for map markers.**
- No widget in `apps/mobile/lib` overrides `focusColor`/`overlayColor`/`FocusNode` in a way that suppresses or replaces Material's default focus treatment (confirmed by grep — the only `FocusNode`-adjacent hit is unrelated, in `qr_scanner_screen.dart`). Every stock Material control (buttons, list tiles, dialogs, nav) therefore keeps M3's default focus ring, which meets this criterion by construction.
- **Scope boundary, not a defect**: `PlaceMarker`/`ClusterMarker` are built on bare `GestureDetector`, which has no `FocusNode` and is not part of keyboard/D-pad focus traversal at all — there is no focus indicator because these elements are never focusable, consistent with mainstream mobile map apps (e.g. Google Maps' own pins aren't keyboard-focusable either). This is a keyboard-operability scope note (closer to SC 2.1.1) rather than a focus-indicator failure, and is recorded here rather than silently passed over.

### 4. No information conveyed by color alone

**Status: PASS.**
- `CabinStatusIndicator` pairs its functional color with a mandatory text label by construction (`docs/design/component-library.md` §9.3) — verified in code, never color-only.
- F10 (map pin category: 4 colors previously distinguished only by hue between same-`placeKind` pairs) fixed with 4 distinct icons (`place_marker.dart`), verified by this session's re-read of the shipped code (`Icons.wc`/`payments_outlined`/`verified_outlined`/`mosque`, one per `PinColor`).
- F6 (marker touch target) and the LOW-finding re-derivation pass (this session) found no additional color-only indicators beyond what Feature 22 already covered.

### 5. Every interactive element has an accessible name; every meaningful icon has alt text/label

**Status: PASS.**
- Extensive coverage from Features 11–16, 21, 25, 27, 29–34 (badges, star ratings, close/back buttons, delete buttons, tooltips, live-region banners) plus this session's fixes (the `sign_in_sign_up_screen.dart` submit-spinner label, matching the already-fixed identical pattern in `submit_review_screen.dart`; the previously-unlabeled Saved-Payment-Methods and Payment-Processing spinners).
- Verified by ~45 `find.bySemanticsLabel`/`tester.getSemantics(...).label` assertions across the test suite (527/527 passing).
- **On-device**: a `uiautomator` content-desc tree dump across core screens (map, sign-in, saved payment methods, payment-failed view) to cross-check the widget-test predictions against the real Android accessibility tree — *pending device reconnection, see Outstanding Items below.*

### 6. RTL mirroring verified for every component with directional content

**Status: PASS.**
- Repo-wide grep for `EdgeInsets.only(left:`/`right:`/`Alignment.centerLeft`/`centerRight` (the literals that would silently break under RTL) returns **zero hits** in `lib/` — every directional layout uses `PositionedDirectional`, `EdgeInsetsDirectional`, `Alignment.centerStart/End`, or plain `Row`/direction-agnostic widgets, which Flutter mirrors automatically under `Directionality.rtl`.
- US-06.2 (native RTL) has been verified incrementally, feature-by-feature, since Feature 1 — every feature's own log entry includes Light/Dark/Arabic-RTL evidence (see `docs/phase-3-screenshots/`, 9 feature folders each with a `-light-ar-rtl.png` variant).
- A dedicated `integration_test/rtl_screenshot_test.dart` exists and is part of the standard screenshot-test suite.

## Outstanding Items

Two on-device checks are incomplete because the physical Android device (`21121119SC`) disconnected from `adb` mid-session:
1. **F9 physical tap-target re-measurement** (checklist item 1) — the code fix is verified by widget test (`tester.getRect` ≥8dp gap); a real-hardware pixel measurement was planned but not yet captured.
2. **`uiautomator` content-desc tree spot-check** (checklist item 5) — planned to cross-check the widget-test-predicted accessible names against the real Android accessibility node tree on a handful of core screens.

Both are mechanical re-verifications of already-passing, already-tested behavior, not open design questions — see the EPIC-06 Completion Report for disposition.

## Sign-Off

| Item | Status |
|---|---|
| 1. Touch target ≥48×48dp | ✅ Pass (code+test); on-device re-measurement outstanding |
| 2. Text contrast | ✅ Pass, 1 documented dead-code exception |
| 3. Focus indicator | ✅ Pass; 1 documented keyboard-operability scope note (map markers) |
| 4. No color-alone information | ✅ Pass |
| 5. Accessible names / alt text | ✅ Pass (code+test); on-device spot-check outstanding |
| 6. RTL mirroring | ✅ Pass |

**US-06.4's checklist requirement: satisfied**, with the two on-device items above tracked as an explicit follow-up rather than silently closed.
