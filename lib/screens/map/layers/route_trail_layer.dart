import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/models.dart';
import '../../../utils/color_blind_palette.dart';

/// Draws the recorded route, splitting it at long time gaps and changes in
/// ping outcome.
class RouteTrailLayer extends StatelessWidget {
  const RouteTrailLayer({
    super.key,
    required this.samples,
    required this.colorBlindMode,
  });

  final List<Sample> samples;
  final String colorBlindMode;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) return const SizedBox.shrink();

    final sorted = List<Sample>.from(samples)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final polylines = <Polyline>[];
    const maxGapMinutes = 5;

    var segmentPoints = <LatLng>[];
    Color segmentColor = Colors.blue;

    for (var i = 0; i < sorted.length; i++) {
      final sample = sorted[i];
      final pointColor = switch (sample.pingSuccess) {
        true => ColorBlindPalette.getSuccessColor(colorBlindMode),
        false => ColorBlindPalette.getFailureColor(colorBlindMode),
        null => Colors.blue,
      };

      if (i > 0) {
        final gap = sample.timestamp
            .difference(sorted[i - 1].timestamp)
            .inMinutes;

        if (gap > maxGapMinutes) {
          if (segmentPoints.length >= 2) {
            polylines.add(_polyline(segmentPoints, segmentColor));
          }
          segmentPoints = [sample.position];
          segmentColor = pointColor;
          continue;
        }

        if (pointColor != segmentColor && segmentPoints.length >= 2) {
          polylines.add(_polyline(segmentPoints, segmentColor));
          segmentPoints = [segmentPoints.last, sample.position];
          segmentColor = pointColor;
          continue;
        }
      } else {
        segmentColor = pointColor;
      }

      segmentPoints.add(sample.position);
    }

    if (segmentPoints.length >= 2) {
      polylines.add(_polyline(segmentPoints, segmentColor));
    }

    return PolylineLayer(polylines: polylines);
  }

  Polyline _polyline(List<LatLng> points, Color color) {
    return Polyline(
      points: List<LatLng>.from(points),
      color: color.withValues(alpha: 0.7),
      strokeWidth: 3,
    );
  }
}
