import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/models.dart';
import '../../../utils/coverage_prediction.dart';

class CoveragePredictionLayer extends StatelessWidget {
  const CoveragePredictionLayer({
    required this.samples,
    required this.repeaters,
    required this.includeOnlyRepeaters,
    super.key,
  });

  final List<Sample> samples;
  final List<Repeater> repeaters;
  final String? includeOnlyRepeaters;

  @override
  Widget build(BuildContext context) {
    final rings = buildCoveragePredictionRings(
      samples: samples,
      repeaters: repeaters,
      includeOnlyRepeaters: includeOnlyRepeaters,
    );
    if (rings.isEmpty) return const SizedBox.shrink();

    return PolygonLayer(
      polygons: rings
          .map((ring) {
            final (color, fillOpacity, borderOpacity) = switch (ring.kind) {
              CoveragePredictionRingKind.edge => (Colors.red, 0.05, 0.35),
              CoveragePredictionRingKind.moderate => (Colors.yellow, 0.08, 0.5),
              CoveragePredictionRingKind.strong => (Colors.green, 0.10, 0.6),
            };
            return Polygon(
              points: _circlePoints(ring.center, ring.radiusMeters),
              color: color.withValues(alpha: fillOpacity),
              borderColor: color.withValues(alpha: borderOpacity),
              borderStrokeWidth: 1.5,
            );
          })
          .toList(growable: false),
    );
  }

  List<LatLng> _circlePoints(
    LatLng center,
    double radiusMeters, {
    int segments = 72,
  }) {
    const distance = Distance();
    return List.generate(segments, (index) {
      final bearing = (360.0 / segments) * index;
      return distance.offset(center, radiusMeters, bearing);
    });
  }
}
