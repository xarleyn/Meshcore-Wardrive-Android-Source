import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Play/stop FAB. Tooltip is omitted because Material's tooltip long-press
/// recognizer would swallow the fresh-session gesture.
class TrackingPlayButton extends StatelessWidget {
  final bool isTracking;
  final VoidCallback onToggle;
  final VoidCallback onStartFreshSession;
  final VoidCallback onToggleQuickSettings;

  const TrackingPlayButton({
    super.key,
    required this.isTracking,
    required this.onToggle,
    required this.onStartFreshSession,
    required this.onToggleQuickSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isTracking
          ? 'Stop tracking'
          : 'Start tracking. Long-press for a blank-map session.',
      child: GestureDetector(
        onDoubleTap: onToggleQuickSettings,
        onLongPress: isTracking
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onStartFreshSession();
              },
        child: FloatingActionButton(
          heroTag: 'tracking',
          onPressed: onToggle,
          backgroundColor: isTracking ? Colors.red : Colors.green,
          child: Icon(isTracking ? Icons.stop : Icons.play_arrow),
        ),
      ),
    );
  }
}
