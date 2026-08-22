import 'package:flutter/material.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';

import '../../../models/models.dart';

/// Renders recorded samples as a weighted ping-success heatmap.
class SampleHeatmapLayer extends StatelessWidget {
  const SampleHeatmapLayer({
    super.key,
    required this.samples,
    required this.reset,
  });

  final List<Sample> samples;
  final Stream<void> reset;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) return const SizedBox.shrink();

    final data = samples.map((sample) {
      final weight = switch (sample.pingSuccess) {
        true => 1.0,
        false => 0.5,
        null => 0.2,
      };
      return WeightedLatLng(sample.position, weight);
    }).toList();

    return HeatMapLayer(
      heatMapDataSource: InMemoryHeatMapDataSource(data: data),
      heatMapOptions: HeatMapOptions(
        gradient: {
          0.25: Colors.green,
          0.50: Colors.yellow,
          0.75: Colors.orange,
          1.0: Colors.red,
        },
        minOpacity: 0.1,
      ),
      reset: reset,
    );
  }
}
