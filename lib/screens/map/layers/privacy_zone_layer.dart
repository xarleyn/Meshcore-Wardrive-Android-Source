import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Displays privacy zones as translucent 48-segment circle polygons.
class PrivacyZoneLayer extends StatelessWidget {
  const PrivacyZoneLayer({super.key, required this.zones});

  final List<Map<String, dynamic>> zones;

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) return const SizedBox.shrink();

    return PolygonLayer(
      polygons: zones
          .map((zone) {
            final center = LatLng(zone['lat'] as double, zone['lon'] as double);
            return Polygon(
              points: _circlePoints(center, zone['radius_meters'] as double),
              color: Colors.grey.withValues(alpha: 0.15),
              borderColor: Colors.grey.withValues(alpha: 0.5),
              borderStrokeWidth: 2,
            );
          })
          .toList(growable: false),
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
