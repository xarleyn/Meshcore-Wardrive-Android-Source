import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../utils/community_coverage.dart';

List<CommunityCoverageCell> visibleCommunityCoverageCells({
  required Map<String, dynamic> rawCoverage,
  required int precision,
  required LatLngBounds visibleBounds,
}) {
  return CommunityCoverage.aggregate(rawCoverage, precision: precision).values
      .where((cell) {
        final total = cell.received + cell.lost;
        return total > 0 &&
            cell.intersectsViewport(
              south: visibleBounds.south,
              north: visibleBounds.north,
              west: visibleBounds.west,
              east: visibleBounds.east,
            );
      })
      .toList(growable: false);
}

class CommunityCoverageLayer extends StatelessWidget {
  const CommunityCoverageLayer({
    required this.rawCoverage,
    required this.precision,
    required this.visibleBounds,
    super.key,
  });

  final Map<String, dynamic> rawCoverage;
  final int precision;
  final LatLngBounds visibleBounds;

  @override
  Widget build(BuildContext context) {
    final cells = visibleCommunityCoverageCells(
      rawCoverage: rawCoverage,
      precision: precision,
      visibleBounds: visibleBounds,
    );

    return PolygonLayer(
      polygons: cells
          .map((cell) {
            final successRate = cell.received / (cell.received + cell.lost);
            final color = successRate >= 0.7
                ? const Color(0x2200CC00)
                : successRate >= 0.3
                ? const Color(0x22CCCC00)
                : const Color(0x22CC0000);

            return Polygon(
              points: cell.polygonPoints,
              color: color,
              borderColor: const Color(0x4400AAEE),
              borderStrokeWidth: 1,
            );
          })
          .toList(growable: false),
    );
  }
}
