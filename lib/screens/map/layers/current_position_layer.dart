import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/location_service.dart';
import '../../../services/settings_service.dart';

/// Displays the current fused or Wi-Fi position, optional heading, and ping
/// pulse.
class CurrentPositionLayer extends StatelessWidget {
  const CurrentPositionLayer({
    super.key,
    required this.position,
    required this.style,
    required this.source,
    required this.heading,
    required this.showPingPulse,
  });

  final LatLng position;
  final CurrentLocationMarkerStyle style;
  final LocationPositionSource source;
  final double heading;
  final bool showPingPulse;

  @override
  Widget build(BuildContext context) {
    final markerSize = style == CurrentLocationMarkerStyle.arrow ? 34.0 : 20.0;
    final markers = <Marker>[
      Marker(
        point: position,
        width: markerSize,
        height: markerSize,
        child: _buildPositionMarker(context),
      ),
    ];

    if (showPingPulse) {
      markers.add(
        Marker(
          point: position,
          width: 60,
          height: 60,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 1 - value),
                    width: 3,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }

  Widget _buildPositionMarker(BuildContext context) {
    final positionColor = source == LocationPositionSource.wifi
        ? Colors.cyan
        : Colors.blue;
    final l10n = AppLocalizations.of(context);
    final positionLabel = source == LocationPositionSource.wifi
        ? l10n.mapCurrentWifiLocation
        : l10n.mapCurrentFusedLocation;

    if (style == CurrentLocationMarkerStyle.circle) {
      return Semantics(
        label: positionLabel,
        child: Container(
          decoration: BoxDecoration(
            color: positionColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      );
    }

    return Semantics(
      label: l10n.mapPositionHeadingSemantics(
        positionLabel,
        '${heading.round()}',
      ),
      child: Transform.rotate(
        angle: heading * math.pi / 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.navigation, size: 34, color: Colors.white),
            Icon(Icons.navigation, size: 27, color: positionColor),
          ],
        ),
      ),
    );
  }
}
