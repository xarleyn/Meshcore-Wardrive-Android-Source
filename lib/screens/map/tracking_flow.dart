import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../../services/achievement_service.dart';
import '../../services/location_service.dart';
import '../../services/settings_service.dart';
import '../../utils/session_map_view.dart';
import 'map_screen_controller.dart';
import 'dialogs/map_workflow_dialogs.dart';

/// Tracking start/stop lifecycle for the map screen.
///
/// Owns the session distance persistence, the tracking/auto-ping state
/// transitions, and the stopped-session map view settlement. The flow owns
/// no state: screen flags resolve through callbacks, and tracking state is
/// applied through [setTrackingState].
class TrackingFlow {
  const TrackingFlow({
    required this.context,
    required this.onShowSnackBar,
    required this.locationService,
    required this.settingsService,
    required this.mapDataController,
    required this.isTracking,
    required this.currentSessionView,
    required this.loraConnected,
    required this.carpeaterEnabled,
    required this.setTrackingState,
    required this.applySessionView,
    required this.prepareAndroidTracking,
  });

  /// Screen context used for mounted checks, localization, and dialogs.
  final BuildContext context;

  /// Shows a transient message; the owner guards this callback with its own
  /// mounted check.
  final void Function(String message) onShowSnackBar;

  final LocationService locationService;
  final SettingsService settingsService;
  final MapScreenController mapDataController;

  /// Current tracking flag, read when toggling.
  final bool Function() isTracking;

  /// Session-scoped map view the screen currently displays.
  final SessionMapView Function() currentSessionView;

  final bool loraConnected;
  final bool carpeaterEnabled;

  /// Applies the tracking flag; [autoPing] `null` leaves the current
  /// auto-ping flag untouched.
  final void Function(bool tracking, bool? autoPing) setTrackingState;

  /// Applies a session map view and reloads map data.
  final void Function(SessionMapView view) applySessionView;

  /// Android permission pre-flight before tracking starts.
  final Future<bool> Function() prepareAndroidTracking;

  /// Starts or stops tracking and auto-ping/Carpeater side effects.
  Future<void> toggleTracking({bool freshSession = false}) async {
    if (isTracking()) {
      await stopTracking();
      return;
    }
    await startTracking(freshSession: freshSession);
  }

  /// Stops tracking, persists the session distance, and settles the map on
  /// the stopped session.
  Future<void> stopTracking() async {
    // Persist session distance before stopping
    final sessionMeters = locationService.totalDistanceMeters;
    if (sessionMeters > 0) {
      await settingsService.addToTotalDistanceDriven(sessionMeters);
    }
    final sessionId = locationService.currentSessionId;
    // Stop tracking and auto-ping
    await locationService.stopTracking();
    locationService.disableAutoPing();
    setTrackingState(false, false);
    await handleStoppedSession(sessionId);
    // Check for newly unlocked achievements
    AchievementService().checkAndUnlock();
  }

  /// Starts tracking, enabling auto-ping or Carpeater when a companion is
  /// connected.
  Future<void> startTracking({bool freshSession = false}) async {
    if (!await prepareAndroidTracking()) return;

    // Start tracking
    final started = await locationService.startTracking();
    if (!started) {
      if (!context.mounted) return;
      onShowSnackBar(
        locationService.lastStartError ??
            AppLocalizations.of(context).mapFailedToStartTracking,
      );
      return;
    }

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    String startMessage = l10n.mapLocationTrackingStarted;
    // Auto-enable ping or Carpeater if LoRa is connected
    if (loraConnected && carpeaterEnabled) {
      locationService.setCarpeaterMode(true);
      final carpeaterStarted = await locationService.startCarpeater();
      setTrackingState(true, false);
      startMessage = carpeaterStarted
          ? l10n.mapCarpeaterModeStarted
          : l10n.mapCarpeaterFailedCheckSettings;
    } else if (loraConnected) {
      locationService.enableAutoPing();
      setTrackingState(true, true);
      startMessage = l10n.mapLocationTrackingAndAutoPingStarted;
    } else {
      setTrackingState(true, null);
    }
    _onTrackingStarted(freshSession: freshSession, startMessage: startMessage);
  }

  /// Settles the map on the session that just stopped.
  ///
  /// Sessions with samples switch the view to them; an empty session is
  /// kept only when the user confirms, otherwise it is discarded.
  Future<void> handleStoppedSession(int? sessionId) async {
    if (sessionId == null || !context.mounted) return;

    final sessions = await mapDataController.getSessions();
    if (!context.mounted) return;
    WSession? finalized;
    for (final session in sessions) {
      if (session.id == sessionId) {
        finalized = session;
        break;
      }
    }
    if (finalized == null) return;

    if (!SessionMapView.isEmptySession(finalized.sampleCount)) {
      applySessionView(currentSessionView().afterStopWithSamples(finalized));
      return;
    }

    final save = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const SaveEmptySessionDialog(),
    );
    if (!context.mounted) return;
    if (save != false) {
      if (currentSessionView().scope == SessionMapScope.session) {
        applySessionView(SessionMapView.session(finalized));
      }
      return;
    }

    await mapDataController.deleteSession(sessionId);
    final remaining = await mapDataController.getSessions();
    if (!context.mounted) return;
    if (currentSessionView().scope != SessionMapScope.session) return;

    applySessionView(currentSessionView().afterDiscardingEmpty(remaining));
    final l10n = AppLocalizations.of(context);
    if (remaining.isEmpty) {
      onShowSnackBar(l10n.mapSessionDiscarded);
    } else {
      onShowSnackBar(l10n.mapSessionDiscardedShowingLast);
    }
  }

  void _onTrackingStarted({
    required bool freshSession,
    required String startMessage,
  }) {
    if (freshSession) {
      final sessionId = locationService.currentSessionId;
      final startTime = locationService.sessionStartTime;
      if (sessionId != null && startTime != null) {
        applySessionView(
          currentSessionView().afterFreshStart(
            WSession(id: sessionId, startTime: startTime),
          ),
        );
        onShowSnackBar(AppLocalizations.of(context).mapNewSessionShowingTrip);
        return;
      }
    }
    applySessionView(currentSessionView().afterShortPressStart());
    onShowSnackBar(startMessage);
  }
}
