import 'package:flutter/material.dart';

/// Callbacks for `MapControlPanel`.
class MapPanelCallbacks {
  const MapPanelCallbacks({
    required this.onConnect,
    required this.onDisconnect,
    required this.onManualPing,
    required this.onCarpeaterRetry,
  });

  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onManualPing;
  final VoidCallback onCarpeaterRetry;
}

/// Callbacks for `MapActionButtons`.
class MapMenuCallbacks {
  const MapMenuCallbacks({
    required this.onCompassPressed,
    required this.onCompassLongPressed,
    required this.onLocationPressed,
    required this.onToggleTracking,
    required this.onStartFreshSession,
    required this.onToggleQuickSettings,
  });

  final VoidCallback onCompassPressed;
  final VoidCallback onCompassLongPressed;
  final VoidCallback onLocationPressed;
  final VoidCallback onToggleTracking;
  final VoidCallback onStartFreshSession;
  final VoidCallback onToggleQuickSettings;
}
