import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../models/models.dart';

class EdgeLayer extends StatelessWidget {
  const EdgeLayer({
    required this.edges,
    required this.filterByWhitelist,
    required this.includeOnlyRepeaters,
    super.key,
  });

  final List<Edge> edges;
  final bool filterByWhitelist;
  final String? includeOnlyRepeaters;

  @override
  Widget build(BuildContext context) {
    final allowedPrefixes =
        filterByWhitelist &&
            includeOnlyRepeaters != null &&
            includeOnlyRepeaters!.isNotEmpty
        ? includeOnlyRepeaters!
              .split(',')
              .map((prefix) => prefix.trim().toUpperCase())
              .toList(growable: false)
        : null;
    final visibleEdges = allowedPrefixes == null
        ? edges
        : edges.where((edge) {
            final repeaterId = edge.repeater.id.toUpperCase();
            return allowedPrefixes.any(repeaterId.startsWith);
          });

    return PolylineLayer(
      polylines: visibleEdges
          .map((edge) {
            return Polyline(
              points: [edge.coverage.position, edge.repeater.position],
              color: Colors.purple.withValues(alpha: 0.6),
              strokeWidth: 2,
            );
          })
          .toList(growable: false),
    );
  }
}
