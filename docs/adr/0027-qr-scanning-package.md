# ADR-0027: QR-Scanning Package — `mobile_scanner` (+ `permission_handler` for the settings deep-link)

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-01 |
| **Deciders** | Engineering team |
| **Phase** | Phase 3 — Flutter Implementation, EPIC-04 US-04.1 |
| **RAH-DOC-005 reference** | §2.5 (FR-PAY-01) |
| **Related** | [Wireframes — SCR-013](../design/wireframes/mobile-emergency-payment.md#scr-013-qr-scanner--flagship), [Domain Model §6](../architecture/domain-model.md#6-bounded-context-access--payment), [Security Architecture §5](../architecture/security-architecture.md), [ADR-0019 — Map/geolocation dependencies](./0019-map-rendering-and-geolocation-dependencies.md), [ADR-0025 — Qibla sensor package](./0025-qibla-compass-sensor-package.md) |

## Context
FR-PAY-01 requires scanning a cabin's QR code to initiate an access session (SCR-013). Flutter has no built-in camera/barcode-decoding API. No QR-scanning package existed in `pubspec.yaml` before this story (confirmed by dependency audit during the EPIC-04 pre-implementation research pass). Candidates:

1. **`mobile_scanner`** — actively maintained (latest release within the current release cadence), MIT-licensed, uses CameraX (Android) / AVFoundation (iOS) natively, exposes a `MobileScannerController` with a `Stream` of `BarcodeCapture` results and built-in permission-state reporting (`MobileScannerException` with `ErrorCode.permissionDenied` distinguishable from other failures) — a direct match for SCR-013's documented `permission-denied` state.
2. **`qr_code_scanner`** — the long-standing incumbent package, but effectively unmaintained (no active releases addressing current Android/iOS embedding APIs); ruled out on maintenance-risk grounds alone, no prototype needed, same category of quick elimination as ADR-0025's treatment of `geolocator`'s heading support.
3. **Hand-rolled camera preview + a barcode-decoding library (e.g. `zxing` bindings)** — full control, but reimplements exactly the kind of native camera-lifecycle and frame-decoding work a purpose-built package already solves, the same reasoning ADR-0025 used to reject hand-rolled sensor fusion.

## Decision
Use **`mobile_scanner` 7.4.0** — resolves cleanly against this project's existing dependency set (confirmed via `flutter pub add --dry-run mobile_scanner`), needs only the standard `CAMERA` runtime permission (declared in `AndroidManifest.xml`, requested at first use via the package's own permission flow), and its exception model maps directly onto SCR-013's three documented states:

- **scanning** — default `MobileScannerController` state, camera preview streaming, scan-target frame pulses.
- **recognized** — first successfully decoded `Barcode.rawValue` from the `BarcodeCapture` stream, frame flashes `success`, controller is stopped (single-scan intent — this flow needs exactly one code, not continuous scanning) before navigating to SCR-014.
- **permission-denied** — `MobileScannerException.errorCode == ErrorCode.permissionDenied` (or the platform reports no camera access) replaces the viewfinder with the rationale card + settings deep-link, per the wireframe.

Only `Barcode.rawValue` (the decoded text payload) is ever read — no reliance on `mobile_scanner`'s barcode-format metadata, since the backend validates the scanned string against live cabin state server-side (Security Architecture §5: "QR codes are per-cabin, server-validated against live `cabin` state"), not the client.

A second, small dependency follows directly from the same wireframe: SCR-013's `permission-denied` state requires a "settings deep-link" button. `mobile_scanner` reports the permission failure but doesn't provide a cross-platform way to open the OS settings screen — **`permission_handler` 13.0.0**'s `openAppSettings()` is the standard solution for exactly this, added alongside `mobile_scanner` rather than hand-rolling a platform-channel call for one button.

**No QR-payload encoding scheme is documented anywhere in the approved specification** (ERD's `access_session.qr_code_scanned` is an untyped `string`; no URI scheme or structured format is specified). Client-side "malformed payload" validation is therefore necessarily a judgment call, not a spec-derived rule — documented here rather than invented silently: reject an empty/whitespace-only decoded value and an implausibly long one (>500 characters — guards against a non-QR barcode format or garbage payload being decoded, not a documented cabin-code length limit), nothing more. Actual cabin-identity validation is entirely the backend's authority, matching Security Architecture §5's explicit statement.

## Alternatives Considered
| Option | Pros | Cons |
|---|---|---|
| `mobile_scanner` (chosen) | Actively maintained; native CameraX/AVFoundation backends; permission-state exceptions map directly to SCR-013's states; resolves cleanly against existing deps | One more native-camera-dependent package to keep current across Flutter/Android SDK upgrades |
| `qr_code_scanner` | Long incumbent, familiar API | Effectively unmaintained against current Android/iOS embedding APIs — ruled out on risk alone |
| Hand-rolled camera + decoding library | Full control | Reimplements native camera lifecycle and frame decoding a purpose-built package already solves — real engineering effort with no documented requirement demanding it |

## Consequences
### Positive
- FR-PAY-01 is satisfied by a maintained, purpose-built package whose exception model already distinguishes the exact states SCR-013 requires.
- No QR-format assumption is baked into the domain layer — `QrCode` (`lib/features/access_payment/domain/entities/qr_code.dart`) only wraps a validated non-empty string; `mobile_scanner`'s barcode-format-specific fields are never touched, keeping the client format-agnostic exactly as Security Architecture §5 implies it should be.
- The mandatory manual-entry accessibility fallback (SCR-013) uses the exact same `QrCode` value type and validation path as a real scan — no divergent logic between the two entry methods.

### Negative / Trade-offs
- The client-side length/emptiness validation (500-character bound) is a judgment call, not a spec-derived number — flagged plainly here, same discipline as ADR-0025's 15° calibration threshold.
- Verified only on the same physical Android device (`21121119SC`) used throughout this log; iOS camera-permission behavior is unverified, consistent with every prior ADR's Android-only verification scope in this project.

## Related
- `lib/features/access_payment/domain/entities/qr_code.dart`, `lib/features/access_payment/presentation/screens/qr_scanner_screen.dart`, `lib/features/access_payment/presentation/providers/qr_scanner_providers.dart`
- `android/app/src/main/AndroidManifest.xml` (`CAMERA` permission)
- `docs/phase-3-implementation-log.md`
