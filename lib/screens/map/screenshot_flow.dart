import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/screenshot_service.dart';
import 'dialogs/map_workflow_dialogs.dart';

/// Screenshot orchestration for the map screen.
///
/// Owns the capture sequence shared by the gallery and coverage-share
/// actions: hide the screen UI, let the frame settle, capture at a high
/// pixel ratio, and restore the UI. Localization, dialogs, and mounted
/// checks resolve against the owning screen's [context].
class ScreenshotFlow {
  const ScreenshotFlow({
    required this.context,
    required this.onShowSnackBar,
    required this.screenshotController,
    required this.screenshotService,
    required this.setUiHidden,
  });

  /// Screen context used for mounted checks, localization, and dialogs.
  final BuildContext context;

  /// Shows a transient message; the owner guards this callback with its own
  /// mounted check.
  final void Function(String message) onShowSnackBar;

  final ScreenshotController screenshotController;
  final ScreenshotService screenshotService;

  /// Hides or restores the map screen chrome for a clean capture.
  final void Function(bool hidden) setUiHidden;

  /// How long the UI waits to settle after hiding before the capture.
  static const Duration _uiSettleDelay = Duration(milliseconds: 300);

  /// Capture pixel ratio for a higher-quality image.
  static const double _capturePixelRatio = 2.0;

  /// Captures the screen with the UI hidden, restoring it afterwards.
  ///
  /// Shows the shared "failed to capture" snackbar and returns null when the
  /// capture produces no image. Exceptions propagate to the caller, which
  /// shows its own error message; the UI is always restored here.
  Future<Uint8List?> captureWithHiddenUi() async {
    setUiHidden(true);
    try {
      // Wait for the UI to settle before capturing.
      await Future.delayed(_uiSettleDelay);
      final bytes = await screenshotController.capture(
        pixelRatio: _capturePixelRatio,
      );
      if (bytes == null && context.mounted) {
        onShowSnackBar(
          AppLocalizations.of(context).mapFailedToCaptureScreenshot,
        );
      }
      return bytes;
    } finally {
      setUiHidden(false);
    }
  }

  /// Captures the map, saves it to the device gallery, and offers to share
  /// the saved image.
  Future<void> saveToGallery() async {
    try {
      final bytes = await captureWithHiddenUi();
      if (bytes == null) return;

      final fileName =
          'meshcore_wardrive_${DateTime.now().millisecondsSinceEpoch}.png';
      final saved = await screenshotService.saveToGallery(bytes, fileName);
      if (!context.mounted) return;
      if (!saved) {
        onShowSnackBar(AppLocalizations.of(context).mapFailedToSaveScreenshot);
        return;
      }
      onShowSnackBar(AppLocalizations.of(context).mapScreenshotSavedToGallery);

      // Ask if user wants to share
      if (!context.mounted) return;
      final shouldShare = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => const ShareScreenshotDialog(),
      );
      if (shouldShare != true || !context.mounted) return;
      await sharePng(
        bytes,
        fileName: 'meshcore_screenshot.png',
        text: AppLocalizations.of(context).mapScreenshotShareText,
      );
    } catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(
        AppLocalizations.of(context).mapErrorCapturingScreenshot('$e'),
      );
    }
  }

  /// Captures the map and shares it with coverage statistics.
  ///
  /// [buildShareText] runs after the capture so the stats reflect the same
  /// state as the shared image; returning null skips the share.
  Future<void> shareCoverageMap({
    required ({String subject, String text})? Function() buildShareText,
  }) async {
    try {
      final bytes = await captureWithHiddenUi();
      if (bytes == null) return;

      final share = buildShareText();
      if (share == null || !context.mounted) return;
      await sharePng(
        bytes,
        fileName:
            'meshcore_coverage_${DateTime.now().millisecondsSinceEpoch}.png',
        subject: share.subject,
        text: share.text,
      );
    } catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapShareFailed('$e'));
    }
  }

  /// Writes [bytes] to a temporary PNG and opens the system share sheet.
  Future<void> sharePng(
    Uint8List bytes, {
    required String fileName,
    String? subject,
    String? text,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject, text: text),
    );
  }
}
