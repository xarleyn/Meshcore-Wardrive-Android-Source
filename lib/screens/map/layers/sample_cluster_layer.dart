import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../services/map_lod_service.dart';
import '../../../utils/color_blind_palette.dart';

class SampleClusterLayer extends StatelessWidget {
  const SampleClusterLayer({
    required this.clusters,
    required this.colorBlindMode,
    required this.hitNotifier,
    required this.onClusterTap,
    super.key,
  });

  final List<SampleCluster> clusters;
  final String colorBlindMode;
  final LayerHitNotifier<SampleCluster> hitNotifier;
  final ValueChanged<SampleCluster> onClusterTap;

  @override
  Widget build(BuildContext context) {
    final circles = clusters
        .map((cluster) {
          final color =
              cluster.successfulCount >= cluster.failedCount &&
                  cluster.successfulCount > 0
              ? ColorBlindPalette.getSuccessColor(colorBlindMode)
              : cluster.failedCount > 0
              ? ColorBlindPalette.getFailureColor(colorBlindMode)
              : ColorBlindPalette.getGpsOnlyColor(colorBlindMode);
          final radius = math.min(
            9.0,
            3.0 + math.log(cluster.sampleCount + 1) / math.ln2,
          );
          return CircleMarker<SampleCluster>(
            point: cluster.position,
            radius: radius,
            color: color.withValues(alpha: 0.7),
            borderColor: color.withValues(alpha: 0.95),
            borderStrokeWidth: 1,
            hitValue: cluster,
          );
        })
        .toList(growable: false);

    return GestureDetector(
      onTap: () {
        final hits = hitNotifier.value?.hitValues;
        if (hits != null && hits.isNotEmpty) onClusterTap(hits.first);
      },
      child: CircleLayer<SampleCluster>(
        circles: circles,
        hitNotifier: hitNotifier,
      ),
    );
  }
}
