# EPIC-06 Completion Report — Bilingual FR/AR & Material 3 Design System

| | |
|---|---|
| **Document ID** | RAH-DOC-042-EPIC-06-REPORT |
| **Phase** | Phase 3 — Flutter Implementation (this log's own numbering; Master Roadmap Phase 5) |
| **Epic** | EPIC-06 — Bilingual FR/AR & Material 3 Design System (`docs/backlog/product-backlog.md:106`) |
| **Version** | 1.0 |
| **Status** | ✅ **Closed** — code/design complete; on-device re-verification deferred (see §5) |
| **Date** | 2026-08-05 |
| **Baseline** | [Implementation Log](./phase-3-implementation-log.md) Features 1–35 · [WCAG Checklist Sign-Off](./design/wcag-2.2-aa-checklist-signoff.md) |

## 1. Objective

Close EPIC-06 (6 user stories, 45 points, cross-cutting across every screen in the app) per the backlog's own definition: native RTL bilingual FR/AR support, user-controllable light/dark M3 theming, and a dedicated WCAG 2.2 AA contrast + screen-reader accessibility pass with a formal checklist sign-off — before any Backend work or new epic starts, per explicit instruction.

## 2. Story-by-Story Status

| Story | Description | Status | Evidence |
|---|---|---|---|
| US-06.1 | Language switch, persists across sessions | ✅ Done | Feature 21 — `shared_preferences`-backed persistence |
| US-06.2 | Native RTL, not mirrored LTR | ✅ Done | Verified incrementally since Feature 1; every feature ships RTL evidence; zero hard-coded `left`/`right`/`centerLeft`/`centerRight` layout literals found repo-wide (re-confirmed this pass) |
| US-06.3 | Native-per-language content, no machine translation | ✅ Done (process requirement, not a dev task, per the backlog's own note) | — |
| US-06.4 | WCAG 2.2 AA contrast/typography/touch-target compliance, dedicated audit + checklist sign-off | ✅ Code/design complete; checklist written and passing on all 6 items; **2 items' on-device re-verification pending** | Features 22–35; [checklist sign-off](./design/wcag-2.2-aa-checklist-signoff.md) |
| US-06.5 | Light/dark theme, user-controllable | ✅ Done | Feature 21 |
| US-06.6 | Custom components composed from M3 primitives | ✅ Done | `QiblaCompass`/`SlatokiTentStatusCard`/`CabinStatusIndicator`, verified by construction |

**5 of 6 stories fully done. US-06.4 is code/design-complete; its own checklist sign-off is written and passing; two items in that sign-off need a physical-device re-confirmation that hasn't run yet (§5).**

## 3. What This Closeout Pass Did

Starting point: after Feature 34, the log recorded EPIC-06 as NOT COMPLETE, with 6 aggregate LOW findings (no exact code locations recorded — the original audit script that assigned their IDs was temporary and never committed), F9's on-device check outstanding, an unfixed observation in `sign_in_sign_up_screen.dart`, and no WCAG checklist sign-off ever performed.

This pass (Features 24–35, this session):
1. **Committed Features 24–34** (10 previously-uncommitted accessibility fixes) as a single clean commit — `e4add0d`.
2. **Re-derived exact code locations** for all 6 LOW findings by matching their one-line aggregate descriptions against real source, since no committed artifact mapped ID → location.
3. **Fixed 4 of the 6 mechanically**: marker shadow-color token discipline (`place_marker.dart`/`cluster_marker.dart`), a live-region double-announcement risk in `payment_processing_screen.dart` (with a narrower fix than the naive one — see §4), a missing loading-spinner label in `saved_payment_methods_screen.dart`, non-live error text in `place_detail_sheet.dart`.
4. **Documented 2 as reviewed-not-fixed**, with rationale: a dark-theme color-token pair confirmed dead (zero usages anywhere in `lib/features/`), and an informational splash-screen timing note that isn't a defect.
5. **Fixed the untracked `sign_in_sign_up_screen.dart` spinner gap** Feature 29 had explicitly flagged but left unfixed.
6. **Wrote the WCAG 2.2 AA checklist sign-off** (`docs/design/wcag-2.2-aa-checklist-signoff.md`) — all 6 checklist items evaluated with cited evidence; 6/6 pass (one with a documented dead-code exception, one with a documented keyboard-operability scope note for map markers).
7. Added 6 new tests; **`flutter analyze`: clean; `flutter test`: 527/527 passing** (up from 521/521).
8. Committed this work as `0816d53`.

## 4. Judgment Calls Worth Recording

- **`payment_processing_screen.dart`'s `_PaymentFailedView`**: the obvious fix (wrap the whole view in `label:` + `ExcludeSemantics`, matching `_ProcessingView` and `map_screen.dart`'s banners) would have been wrong — this view has two real buttons (Retry, back-to-map) below the icon/title, and `ExcludeSemantics` on the whole subtree would have silently stripped their own accessible names. The fix scopes the live region to just the icon+title, leaving the buttons as unwrapped siblings. Caught during implementation, not shipped as the naive version — verified by a test that explicitly asserts both buttons keep their own semantics after the fix.
- **Map pin border color**: `place_marker.dart`'s hard-coded `Colors.white` border looked like a token-discipline violation (the file's own doc comment claims "never a hard-coded Color"), but was reviewed and kept deliberately — it needs to stay legible against real map-tile imagery, which doesn't follow the app's own light/dark theme, the same "generic UI chrome, not a status color" exception `ClusterMarker`'s own doc comment already claims for itself. Not every hard-coded color is a bug; this one was investigated and consciously kept, not blindly "fixed" into a regression.
- **Dead-code color-token pair**: rather than hand-editing `packages/design-tokens/color.json` (a Phase-2-signed-off governance file) to fix a contrast ratio nothing renders, this was documented instead — matching this project's own established preference (see F17's precedent) for not touching things that don't need touching just to close a checklist line item.

## 5. Deferred: On-Device Re-Verification

**Decision (2026-08-05): proceed without the on-device check for now.** The device did not reconnect; rather than block EPIC-06 closure and downstream work on physical-hardware availability, the two items below are deferred as tracked follow-up rather than treated as an open blocker.

A physical Android device (model `21121119SC`) was connected via `adb` for this pass and successfully used to build and install two debug APKs. It disconnected from `adb` partway through the on-device verification step (Windows reports its ADB interface status as "Unknown") before either of the following could run:

| Item | What it re-confirms | Why it's not a design/code gap |
|---|---|---|
| F9 physical tap-target measurement | The ≥8dp gap between Saved Payment Methods' controls, already asserted by `tester.getRect` in a widget test | Purely a real-hardware pixel-density sanity check on an already-passing, already-tested logical measurement |
| `uiautomator` accessible-name spot-check | That the real Android accessibility node tree matches the ~45 `bySemanticsLabel`/`SemanticsNode.label` widget-test assertions already passing | Flutter's semantics tree (what the widget tests check) is the same data Android's accessibility APIs consume — this is a cross-check, not a first-time verification |

Both are mechanical confirmations of behavior already verified by automated tests, not open questions. **No iOS device or macOS host was available in this environment at any point**, so VoiceOver-specific verification was never in scope for this pass — noted explicitly rather than left implicit.

**To close this out later**: reconnect the device (or provide a replacement device/emulator with TalkBack available), then re-run the two checks above. Both are expected to pass given the underlying logic they check is already tested and unchanged since it passed. This is now tracked as follow-up work, not a gate on subsequent epics.

## 6. Recommendation

**Proceeding without the two §5 on-device re-verifications, per explicit instruction (2026-08-05).** Everything within this environment's control is done: every finding fixed or reasonedly dispositioned, the checklist written and passing, 527/527 tests green, two clean commits (`e4add0d`, `0816d53`). The remaining gap is a single external dependency (physical device availability) carried forward as tracked follow-up, not unresolved engineering or design work, and does not block Backend or subsequent epic work.

## 7. Sign-off

| Item | Status |
|---|---|
| All EPIC-06 Exit Review findings resolved or dispositioned | ✅ Complete |
| WCAG 2.2 AA checklist sign-off written | ✅ Complete — [`docs/design/wcag-2.2-aa-checklist-signoff.md`](./design/wcag-2.2-aa-checklist-signoff.md) |
| `flutter analyze` / `flutter test` | ✅ Clean / 527/527 passing |
| Features 24–35 committed | ✅ `e4add0d`, `0816d53` |
| F9 on-device re-measurement | ⬜ Deferred — tracked follow-up, not blocking |
| On-device accessible-name spot-check | ⬜ Deferred — tracked follow-up, not blocking |

**EPIC-06: closed. Code and design work complete; the two on-device re-verifications in §5 are deferred as tracked follow-up and do not block downstream work.**
