import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

typedef PlannedMarkerTapCallback = void Function(Map<String, dynamic> marker);

/// Displays user-planned map markers and forwards the original marker data on
/// tap.
class PlannedMarkerLayer extends StatelessWidget {
  const PlannedMarkerLayer({
    super.key,
    required this.markers,
    required this.onMarkerTap,
  });

  final List<Map<String, dynamic>> markers;
  final PlannedMarkerTapCallback onMarkerTap;

  @override
  Widget build(BuildContext context) {
    if (markers.isEmpty) return const SizedBox.shrink();

    return MarkerLayer(
      markers: markers
          .map((marker) {
            return Marker(
              point: LatLng(marker['lat'] as double, marker['lon'] as double),
              width: 36,
              height: 36,
              child: GestureDetector(
                onTap: () => onMarkerTap(marker),
                child: const Icon(
                  Icons.add_location,
                  color: Colors.amber,
                  size: 36,
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
