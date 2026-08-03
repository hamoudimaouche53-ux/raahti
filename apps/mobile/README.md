# apps/mobile

Flutter application (Android + iOS), Material Design 3 — see `docs/adr/0002-mobile-framework-selection.md` and `docs/adr/0011-material-design-3-as-design-system.md`.

**Implementation started in Phase 3 (this conversation's phase numbering — Flutter Implementation).** Internal structure is feature-first, mirroring the backend bounded contexts — see `docs/architecture/repository-structure.md` §4 and `docs/adr/0018-flutter-project-foundation.md` for the concrete layout adopted.

## Run locally

```
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
```
