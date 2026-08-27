import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ZoneOverlay {
  const ZoneOverlay({required this.center, required this.radiusMeters});

  final LatLng center;
  final double radiusMeters;
}

/// Displays circular map zones with a fixed-size center point and their
/// configured radius.
class ZoneOverlayLayer extends StatelessWidget {
  const ZoneOverlayLayer({required this.zones, required this.color, super.key});

  final List<ZoneOverlay> zones;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        PolygonLayer(
          polygons: [
            for (final zone in zones)
              Polygon(
                points: _circlePoints(zone.center, zone.radiusMeters),
                color: color.withValues(alpha: 0.15),
                borderColor: color.withValues(alpha: 0.7),
                borderStrokeWidth: 2,
              ),
          ],
        ),
        CircleLayer(
          circles: [
            for (final zone in zones)
              CircleMarker(
                point: zone.center,
                radius: 5,
                color: color.withValues(alpha: 0.9),
                borderColor: Colors.white.withValues(alpha: 0.9),
                borderStrokeWidth: 1.5,
              ),
          ],
        ),
      ],
    );
  }

  List<LatLng> _circlePoints(LatLng center, double radiusMeters) {
    const distance = Distance();
    return List.generate(48, (index) {
      final bearing = (360.0 / 48) * index;
      return distance.offset(center, radiusMeters, bearing);
    });
  }
}
