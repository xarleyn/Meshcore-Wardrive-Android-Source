import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/android_tracking_settings_service.dart';
import 'dialogs/map_workflow_dialogs.dart';

/// Android permission prelude for starting tracking.
///
/// Requests, in order: foreground location, precise location, background
/// location, battery optimizations exemption, and disabled Wi-Fi scan
/// throttling. Explanatory dialogs are shown before each system prompt.
///
/// The helper owns no state: the caller passes the owning screen's [context]
/// for mounted checks, localization, and dialogs, the platform settings
/// service for the Wi-Fi throttling steps, and a getter for the
/// beacon-DB Wi-Fi positioning preference.
class TrackingPermissions {
  const TrackingPermissions({
    required this.context,
    required this.androidTrackingSettings,
    required this.beaconDbWifiPositioning,
  });

  /// Screen context used for mounted checks, localization, and dialogs.
  final BuildContext context;

  final AndroidTrackingSettingsService androidTrackingSettings;

  /// Whether beacon-DB Wi-Fi positioning is enabled; when true, Wi-Fi scan
  /// throttling must be disabled before tracking starts.
  final bool Function() beaconDbWifiPositioning;

  /// Runs the full permission chain; returns whether tracking may start.
  Future<bool> prepareAndroidTracking() async {
    if (!Platform.isAndroid) return true;

    final foregroundStatus = await Permission.locationWhenInUse.request();
    if (!foregroundStatus.isGranted) return true;

    final accuracy = await Geolocator.getLocationAccuracy();
    if (accuracy != LocationAccuracyStatus.precise) {
      if (!context.mounted) return false;
      final l10n = AppLocalizations.of(context);
      await _showSettingsDialog(
        title: l10n.mapPreciseLocationRequiredTitle,
        message: l10n.mapPreciseLocationRequiredBody,
        actionLabel: l10n.mapOpenAppSettings,
        onOpen: openAppSettings,
      );
      return false;
    }

    var backgroundStatus = await Permission.locationAlways.status;
    if (!backgroundStatus.isGranted) {
      if (!context.mounted) return false;
      final l10n = AppLocalizations.of(context);
      final shouldRequest = await _showRequestDialog(
        title: l10n.mapAllowLocationAllTheTimeTitle,
        message: l10n.mapAllowLocationAllTheTimeBody,
      );
      if (!shouldRequest) return false;

      backgroundStatus = await Permission.locationAlways.request();
      if (!backgroundStatus.isGranted) {
        if (!context.mounted) return false;
        final l10n = AppLocalizations.of(context);
        await _showSettingsDialog(
          title: l10n.mapBackgroundLocationRequiredTitle,
          message: l10n.mapBackgroundLocationRequiredBody,
          actionLabel: l10n.mapOpenAppSettings,
          onOpen: openAppSettings,
        );
        return false;
      }
    }

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      if (!context.mounted) return false;
      final l10n = AppLocalizations.of(context);
      final shouldRequest = await _showRequestDialog(
        title: l10n.mapUnrestrictedBatteryTitle,
        message: l10n.mapUnrestrictedBatteryBody,
      );
      if (shouldRequest) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }

    if (beaconDbWifiPositioning()) {
      if (!await requestWifiScanThrottlingDisabled()) return false;
    }

    return true;
  }

  /// Asks to disable Wi-Fi scan throttling via developer options; returns
  /// whether tracking may proceed (false only when settings were opened and
  /// the user must return after changing them).
  Future<bool> requestWifiScanThrottlingDisabled() async {
    if (!Platform.isAndroid) return true;

    final throttlingEnabled = await androidTrackingSettings
        .isWifiScanThrottlingEnabled();
    if (throttlingEnabled == false || !context.mounted) return true;

    final l10n = AppLocalizations.of(context);
    final openedSettings = await _showSettingsDialog(
      title: l10n.mapDisableWifiThrottlingTitle,
      message: l10n.mapDisableWifiThrottlingBody,
      actionLabel: l10n.mapDeveloperOptions,
      onOpen: androidTrackingSettings.openWifiScanThrottlingSettings,
    );
    return !openedSettings;
  }

  Future<bool> _showRequestDialog({
    required String title,
    required String message,
  }) async {
    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) =>
              ContinueRequestDialog(title: title, message: message),
        ) ??
        false;
  }

  Future<bool> _showSettingsDialog({
    required String title,
    required String message,
    required String actionLabel,
    required Future<bool> Function() onOpen,
  }) async {
    if (!context.mounted) return false;
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => OpenSettingsDialog(
        title: title,
        message: message,
        actionLabel: actionLabel,
      ),
    );
    if (shouldOpen != true) return false;
    return onOpen();
  }
}
