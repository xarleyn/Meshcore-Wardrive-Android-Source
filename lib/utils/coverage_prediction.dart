import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../services/aggregation_service.dart';

enum CoveragePredictionRingKind { strong, moderate, edge }

class CoveragePredictionRing {
  final LatLng center;
  final double radiusMeters;
  final CoveragePredictionRingKind kind;

  const CoveragePredictionRing({
    required this.center,
    required this.radiusMeters,
    required this.kind,
  });
}

/// Builds percentile-based coverage predictions from successful observations.
///
/// Each repeater needs at least three usable samples. The outer edge uses the
/// maximum observed distance, while the moderate and strong rings use the 75th
/// and 25th percentiles respectively.
List<CoveragePredictionRing> buildCoveragePredictionRings({
  required Iterable<Sample> samples,
  required Iterable<Repeater> repeaters,
  String? includeOnlyRepeaters,
}) {
  const distance = Distance();
  final repeaterByLookupKey = <String, Repeater>{};
  final distancesByLookupKey = <String, List<double>>{};
  final allowedPrefixes =
      includeOnlyRepeaters != null && includeOnlyRepeaters.isNotEmpty
      ? includeOnlyRepeaters
            .split(',')
            .map((prefix) => prefix.trim().toUpperCase())
            .toList(growable: false)
      : null;

  for (final repeater in repeaters) {
    if (repeater.position.latitude == 0.0 &&
        repeater.position.longitude == 0.0) {
      continue;
    }

    if (allowedPrefixes != null) {
      final repeaterId = repeater.id.toUpperCase();
      if (!allowedPrefixes.any(repeaterId.startsWith)) {
        continue;
      }
    }

    final lookupKey = AggregationService.repeaterLookupKey(repeater.id);
    repeaterByLookupKey[lookupKey] = repeater;
  }

  for (final sample in samples) {
    final path = sample.path;
    if (sample.pingSuccess != true || path == null || path.isEmpty) {
      continue;
    }

    final lookupKey = AggregationService.repeaterLookupKey(path);
    final repeater = repeaterByLookupKey[lookupKey];
    if (repeater == null) {
      continue;
    }

    final distanceMeters = distance.as(
      LengthUnit.Meter,
      sample.position,
      repeater.position,
    );
    if (distanceMeters > 100000) {
      continue;
    }

    distancesByLookupKey
        .putIfAbsent(lookupKey, () => <double>[])
        .add(distanceMeters);
  }

  final rings = <CoveragePredictionRing>[];
  for (final entry in distancesByLookupKey.entries) {
    final repeater = repeaterByLookupKey[entry.key]!;
    final distances = entry.value..sort();
    if (distances.length < 3) {
      continue;
    }

    final p25 = distances[(distances.length * 0.25).floor()];
    final p75 = distances[(distances.length * 0.75).floor()];
    final maxDistance = distances.last;
    if (maxDistance < 50) {
      continue;
    }

    rings.add(
      CoveragePredictionRing(
        center: repeater.position,
        radiusMeters: maxDistance,
        kind: CoveragePredictionRingKind.edge,
      ),
    );

    if (p75 > 50 && p75 < maxDistance * 0.95) {
      rings.add(
        CoveragePredictionRing(
          center: repeater.position,
          radiusMeters: p75,
          kind: CoveragePredictionRingKind.moderate,
        ),
      );
    }

    if (p25 > 50 && p25 < p75 * 0.95) {
      rings.add(
        CoveragePredictionRing(
          center: repeater.position,
          radiusMeters: p25,
          kind: CoveragePredictionRingKind.strong,
        ),
      );
    }
  }

  return rings;
}
