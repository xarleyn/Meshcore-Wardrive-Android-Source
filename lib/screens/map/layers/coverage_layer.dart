import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geohash_plus/geohash_plus.dart' as geohash;
import 'package:latlong2/latlong.dart';

import '../../../models/models.dart';
import '../../../services/aggregation_service.dart';

class CoverageLayer extends StatelessWidget {
  const CoverageLayer({
    required this.coverages,
    required this.colorMode,
    required this.colorBlindMode,
    required this.hitNotifier,
    required this.onCoverageTap,
    super.key,
  });

  final List<Coverage> coverages;
  final String colorMode;
  final String colorBlindMode;
  final LayerHitNotifier<Coverage> hitNotifier;
  final ValueChanged<Coverage> onCoverageTap;

  @override
  Widget build(BuildContext context) {
    final polygons = coverages
        .map((coverage) {
          final hash = geohash.GeoHash.decode(coverage.id);
          final color = Color(
            AggregationService.getCoverageColor(
              coverage,
              colorMode,
              colorBlindMode: colorBlindMode,
            ),
          );
          final southWest = hash.bounds.southWest;
          final northEast = hash.bounds.northEast;
          return Polygon<Coverage>(
            points: [
              LatLng(southWest.latitude, southWest.longitude),
              LatLng(southWest.latitude, northEast.longitude),
              LatLng(northEast.latitude, northEast.longitude),
              LatLng(northEast.latitude, southWest.longitude),
            ],
            color: color.withValues(
              alpha: AggregationService.getCoverageOpacity(coverage),
            ),
            borderColor: color,
            borderStrokeWidth: 1,
            hitValue: coverage,
          );
        })
        .toList(growable: false);

    return GestureDetector(
      onTap: () {
        final hits = hitNotifier.value?.hitValues;
        if (hits != null && hits.isNotEmpty) onCoverageTap(hits.first);
      },
      child: PolygonLayer<Coverage>(
        polygons: polygons,
        hitNotifier: hitNotifier,
      ),
    );
  }
}
