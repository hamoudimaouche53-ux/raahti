import "dart:async";

import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:mobile_scanner/mobile_scanner.dart";
import "package:permission_handler/permission_handler.dart";

import "../../../../core/router/app_router.dart";
import "../../../../core/theme/color_tokens.dart";
import "../../../../core/theme/motion_tokens.dart";
import "../../../../core/theme/shape_tokens.dart";
import "../../../../core/theme/spacing_tokens.dart";
import "../../../../l10n/app_localizations.dart";
import "../../domain/entities/access_session.dart";
import "../../domain/entities/qr_code.dart";

/// This screen's overlay renders on top of a live camera feed, not the
/// app's `colorScheme.surface` — so its colors are **deliberately
/// theme-independent**, not a token-discipline oversight. Using
/// theme-aware colors (e.g. `colorScheme.onSurface`) would be wrong: in
/// light theme that resolves near-black, invisible against a dark scrim
/// over a dark camera scene. Every reference camera/scanner UI (platform
/// camera apps, other QR scanners) uses a fixed dark-scrim/white-content
/// overlay regardless of the app's own theme, for exactly this reason.
/// [scrim]'s 60% opacity is chosen deliberately, not arbitrarily: computed
/// worst-case (a pure-white camera background behind it) still yields
/// ≈5.74:1 contrast for [onScrim] text — comfortably above the 4.5:1 floor
/// — found and consolidated as part of the US-06.4 audit (finding F4),
/// which flagged the previously-scattered raw `Colors.*` literals (some
/// correctly backed by this same scrim, two — the AppBar back button and
/// the manual-entry button — with no backdrop at all, rendering directly
/// against the unpredictable live feed) as the actual gap.
abstract final class _ScannerOverlayColors {
  static const Color scrim = Color(0x99000000);
  static const Color onScrim = Colors.white;
  static const Color onScrimSecondary = Colors.white70;

  /// The full-screen fallback background ([Scaffold.backgroundColor],
  /// [_CameraErrorView]'s replace-the-viewfinder state) — solid, not a
  /// scrim over anything, so plain black/white is already
  /// contrast-maximal (21:1) regardless of theme.
  static const Color solidBackground = Colors.black;
}

/// SCR-013 — QR Scanner (US-04.1, FR-PAY-01), pushed as a root-level,
/// full-screen route (`AppRoutePaths.accessPaymentScan`) so it escapes
/// the bottom-nav shell, same precedent as `QiblaFullScreen`.
///
/// Only validates the raw scanned/entered value locally (via [QrCode] —
/// cheap, synchronous, no network) before handing off to SCR-014
/// (`CabinAvailabilityScreen`, US-04.2), which owns the actual
/// `POST /access-sessions` call and its availability outcome. Pops with
/// the [AccessSession] SCR-014 resolves on success, or `null` if the user
/// cancels via the back button — the caller decides what happens next.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  late final MobileScannerController _controller;
  StreamSubscription<BarcodeCapture>? _subscription;
  bool _recognized = false;

  /// Guards against processing more than one detection per scan attempt —
  /// the camera keeps emitting frames until [_controller] is stopped, and
  /// stopping is itself asynchronous.
  bool _processed = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
    _subscription = _controller.barcodes.listen(_onDetect);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    final String? rawValue = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (rawValue == null) return;

    _processed = true;
    setState(() => _recognized = true);
    unawaited(_controller.stop());
    unawaited(_handleRawValue(rawValue));
  }

  Future<void> _restartScanning() async {
    if (!mounted) return;
    setState(() {
      _recognized = false;
      _processed = false;
    });
    await _controller.start();
  }

  Future<void> _openManualEntryDialog() async {
    await _controller.stop();
    if (!mounted) return;
    final String? entered = await showDialog<String>(
      context: context,
      builder: (context) => const _ManualEntryDialog(),
    );
    if (!mounted) return;
    if (entered == null) {
      await _controller.start();
      return;
    }
    setState(() {
      _recognized = true;
      _processed = true;
    });
    await _handleRawValue(entered);
  }

  /// Validates [rawValue] locally, then transitions to SCR-014. An
  /// [InvalidQrCodeFailure] here means nothing was ever sent to the
  /// network — SCR-014's states (`checking`/`available`/`unavailable`)
  /// are all about a request that *was* made, so an invalid value is
  /// handled entirely on this screen instead: an inline message, then
  /// scanning resumes.
  Future<void> _handleRawValue(String rawValue) async {
    final QrCode qrCode;
    try {
      qrCode = QrCode(rawValue);
    } on InvalidQrCodeFailure {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).qrScannerInvalidCodeError),
        ),
      );
      await _restartScanning();
      return;
    }

    if (!mounted) return;
    final AccessSession? session = await context.push<AccessSession>(
      AppRoutePaths.accessPaymentAvailability,
      extra: qrCode.value,
    );
    if (!mounted) return;
    if (session != null) {
      Navigator.of(context).pop(session);
    } else {
      await _restartScanning();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: _ScannerOverlayColors.solidBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Previously the default (theme-dependent) back icon rendered
        // directly against the live camera feed with no backdrop — a
        // real, unguarded contrast risk (US-06.4 finding F4), unlike the
        // instruction pill below, which was already scrim-backed. Wrapped
        // in the same proven-safe scrim; still a real `BackButton` (not a
        // bare `IconButton`) so it keeps its automatic localized tooltip.
        leading: Padding(
          padding: const EdgeInsets.all(RahatiSpacing.space2),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: _ScannerOverlayColors.scrim,
              shape: BoxShape.circle,
            ),
            child: const BackButton(color: _ScannerOverlayColors.onScrim),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            errorBuilder: (context, error) => _CameraErrorView(error: error),
          ),
          Center(child: _ScanTargetFrame(recognized: _recognized)),
          Positioned(
            left: 0,
            right: 0,
            bottom: RahatiSpacing.space8,
            child: Column(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: RahatiSpacing.space6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: RahatiSpacing.space4,
                    vertical: RahatiSpacing.space2,
                  ),
                  decoration: const BoxDecoration(
                    color: _ScannerOverlayColors.scrim,
                    borderRadius: RahatiShape.mediumRadius,
                  ),
                  child: Text(
                    l10n.qrScannerInstruction,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ScannerOverlayColors.onScrim,
                    ),
                  ),
                ),
                const SizedBox(height: RahatiSpacing.space2),
                // Previously unguarded — no backdrop at all, rendering
                // directly against the live camera feed (US-06.4 finding
                // F4). Now scrim-backed like the instruction pill above,
                // instead of sitting bare on an unpredictable background.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RahatiSpacing.space4,
                    vertical: RahatiSpacing.space1,
                  ),
                  decoration: const BoxDecoration(
                    color: _ScannerOverlayColors.scrim,
                    borderRadius: RahatiShape.mediumRadius,
                  ),
                  child: TextButton(
                    onPressed: _openManualEntryDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: _ScannerOverlayColors.onScrim,
                    ),
                    child: Text(l10n.qrScannerManualEntryButton),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Component Library / SCR-013 wireframe — centered square scan-target
/// frame, `shape-medium` corners, `primary` outline. Pulses gently while
/// scanning; flashes `success` once a code is [recognized], per the
/// wireframe's exact state names.
class _ScanTargetFrame extends StatefulWidget {
  const _ScanTargetFrame({required this.recognized});

  final bool recognized;

  @override
  State<_ScanTargetFrame> createState() => _ScanTargetFrameState();
}

class _ScanTargetFrameState extends State<_ScanTargetFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: RahatiMotionDuration.long1,
  );
  late final Animation<double> _pulseOpacity = CurvedAnimation(
    parent: _pulseController,
    curve: Curves.easeInOut,
  ).drive(Tween<double>(begin: 1, end: 0.5));

  @override
  void initState() {
    super.initState();
    if (!widget.recognized) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ScanTargetFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recognized && !oldWidget.recognized) {
      _pulseController.stop();
    } else if (!widget.recognized && oldWidget.recognized) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RahatiFunctionalColors functionalColors = Theme.of(
      context,
    ).extension<RahatiFunctionalColors>()!;
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color borderColor = widget.recognized
        ? functionalColors.success
        : primary;

    return AnimatedBuilder(
      animation: _pulseOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: widget.recognized ? 1 : _pulseOpacity.value,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: RahatiMotionDuration.medium2,
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 3),
          borderRadius: RahatiShape.mediumRadius,
        ),
      ),
    );
  }
}

/// SCR-013's `permission-denied` state (and the generic-camera-error
/// fallback for `unsupported`/other codes) — replaces the viewfinder
/// entirely, per the wireframe.
class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool permissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: _ScannerOverlayColors.solidBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(RahatiSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.no_photography_outlined,
                size: 48,
                color: _ScannerOverlayColors.onScrim,
              ),
              const SizedBox(height: RahatiSpacing.space4),
              Text(
                permissionDenied
                    ? l10n.qrScannerPermissionDeniedTitle
                    : l10n.qrScannerCameraUnavailable,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _ScannerOverlayColors.onScrim,
                ),
                textAlign: TextAlign.center,
              ),
              if (permissionDenied) ...<Widget>[
                const SizedBox(height: RahatiSpacing.space2),
                Text(
                  l10n.qrScannerPermissionDeniedBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _ScannerOverlayColors.onScrimSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: RahatiSpacing.space4),
                FilledButton(
                  onPressed: openAppSettings,
                  child: Text(l10n.qrScannerOpenSettingsButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The mandatory non-visual accessibility fallback — camera-based QR
/// scanning has no reliable non-visual equivalent, so this dialog is the
/// alternative entry point into the same [InitiateAccessSession] flow.
class _ManualEntryDialog extends StatefulWidget {
  const _ManualEntryDialog();

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.qrScannerManualEntryDialogTitle),
      content: TextField(
        controller: _textController,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.qrScannerManualEntryFieldLabel,
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.qrScannerManualEntryCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_textController.text),
          child: Text(l10n.qrScannerManualEntrySubmit),
        ),
      ],
    );
  }
}
