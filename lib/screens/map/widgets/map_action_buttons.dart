import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../utils/compass_calibration.dart';
import '../../../widgets/tracking_play_button.dart';

class MapActionButtons extends StatelessWidget {
  const MapActionButtons({
    required this.isTracking,
    required this.compassInUse,
    required this.lockRotationNorth,
    required this.followHeading,
    required this.compassAccuracyStatus,
    required this.followLocation,
    required this.onCompassPressed,
    required this.onCompassLongPressed,
    required this.onLocationPressed,
    required this.onToggleTracking,
    required this.onStartFreshSession,
    required this.onToggleQuickSettings,
    super.key,
  });

  final bool isTracking;
  final bool compassInUse;
  final bool lockRotationNorth;
  final bool followHeading;
  final CompassAccuracyStatus compassAccuracyStatus;
  final bool followLocation;
  final VoidCallback onCompassPressed;
  final VoidCallback onCompassLongPressed;
  final VoidCallback onLocationPressed;
  final VoidCallback onToggleTracking;
  final VoidCallback onStartFreshSession;
  final VoidCallback onToggleQuickSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onLongPress: onCompassLongPressed,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton(
                heroTag: 'compass',
                mini: true,
                onPressed: onCompassPressed,
                tooltip: compassInUse && !lockRotationNorth
                    ? followHeading
                          ? l10n.mapStopHeadingUp
                          : l10n.mapRotateMapWithHeading
                    : l10n.mapResetToNorth,
                backgroundColor: followHeading ? Colors.blue : null,
                child: const Icon(Icons.navigation),
              ),
              if (compassInUse &&
                  compassAccuracyStatus ==
                      CompassAccuracyStatus.needsCalibration)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.error, size: 14, color: Colors.orange),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'location',
          mini: true,
          onPressed: onLocationPressed,
          backgroundColor: followLocation ? Colors.blue : null,
          child: Icon(followLocation ? Icons.gps_fixed : Icons.gps_not_fixed),
        ),
        const SizedBox(height: 8),
        TrackingPlayButton(
          isTracking: isTracking,
          onToggle: onToggleTracking,
          onStartFreshSession: onStartFreshSession,
          onToggleQuickSettings: onToggleQuickSettings,
        ),
      ],
    );
  }
}
