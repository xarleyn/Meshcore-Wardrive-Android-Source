import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../utils/geohash_utils.dart';
import 'aggregation_service.dart';

/// Builds zoom-dependent map data so map layers do not need to render every
/// stored observation while the camera is zoomed out.
class MapLodService {
  static const int _minimumPrecision = 3;

  /// Chooses a geohash precision whose cells stay roughly 30-100 pixels wide.
  ///
  /// A new precision is selected only every two zoom levels. This keeps the
  /// rendered object count low and avoids rebuilding layers continuously while
  /// pinch-zooming.
  static int precisionForZoom(double zoom, {required int maxPrecision}) {
    final zoomPrecision = (zoom / 2).floor();
    return zoomPrecision.clamp(_minimumPrecision, maxPrecision).toInt();
  }

  static List<Coverage> aggregateCoverages(
    Iterable<Coverage> coverages, {
    required int precision,
  }) {
    final buckets = <String, _CoverageBucket>{};

    for (final coverage in coverages) {
      final key = _keyAtPrecision(
        coverage.id,
        coverage.position.latitude,
        coverage.position.longitude,
        precision,
      );
      final bucket = buckets.putIfAbsent(key, () => _CoverageBucket());
      bucket.received += coverage.received;
      bucket.lost += coverage.lost;
      bucket.lastReceived = _latest(bucket.lastReceived, coverage.lastReceived);
      bucket.updated = _latest(bucket.updated, coverage.updated);
      bucket.repeaters.addAll(coverage.repeaters);
    }

    return buckets.entries
        .map(
          (entry) => Coverage(
            id: entry.key,
            position: GeohashUtils.posFromHash(entry.key),
            received: entry.value.received,
            lost: entry.value.lost,
            lastReceived: entry.value.lastReceived,
            updated: entry.value.updated,
            repeaters: entry.value.repeaters.toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  static List<Edge> aggregateEdges(
    Iterable<Edge> edges,
    Iterable<Coverage> lodCoverages, {
    required int precision,
  }) {
    final coverageById = {
      for (final coverage in lodCoverages) coverage.id: coverage,
    };
    final uniqueEdges = <String, Edge>{};

    for (final edge in edges) {
      final coverageId = _keyAtPrecision(
        edge.coverage.id,
        edge.coverage.position.latitude,
        edge.coverage.position.longitude,
        precision,
      );
      final coverage = coverageById[coverageId];
      if (coverage == null) continue;

      final repeaterId = AggregationService.repeaterLookupKey(edge.repeater.id);
      uniqueEdges.putIfAbsent(
        '$coverageId|$repeaterId',
        () => Edge(coverage: coverage, repeater: edge.repeater),
      );
    }

    return uniqueEdges.values.toList(growable: false);
  }

  /// Buckets samples by geohash prefix and returns one cluster per bucket.
  ///
  /// By default the marker sits at the bucket cell center, which keeps the
  /// position stable while new measurements arrive. With [anchorAtCentroid]
  /// the marker is placed at the average position of the member samples
  /// instead, so grouped points stay close to where they were actually
  /// recorded.
  static List<SampleCluster> aggregateSamples(
    Iterable<Sample> samples, {
    required int precision,
    bool anchorAtCentroid = false,
  }) {
    final buckets = <String, _SampleBucket>{};

    for (final sample in samples) {
      final key = _keyAtPrecision(
        sample.geohash,
        sample.position.latitude,
        sample.position.longitude,
        precision,
      );
      final bucket = buckets.putIfAbsent(key, () => _SampleBucket());
      bucket.add(sample);
    }

    return buckets.entries
        .map((entry) {
          final bucket = entry.value;
          return SampleCluster(
            id: entry.key,
            position: anchorAtCentroid
                ? bucket.centroid
                : GeohashUtils.posFromHash(entry.key),
            sampleCount: bucket.sampleCount,
            successfulCount: bucket.successfulCount,
            failedCount: bucket.failedCount,
            gpsOnlyCount: bucket.gpsOnlyCount,
            newestSample: bucket.newestSample!,
            samples: List<Sample>.unmodifiable(bucket.samples),
          );
        })
        .toList(growable: false);
  }

  /// One marker per sample at its recorded GPS position, oldest first.
  static List<SampleCluster> individualSamples(Iterable<Sample> samples) {
    final clusters = samples
        .map(
          (sample) => SampleCluster(
            id: sample.id,
            position: sample.position,
            sampleCount: 1,
            successfulCount: sample.pingSuccess == true ? 1 : 0,
            failedCount: sample.pingSuccess == false ? 1 : 0,
            gpsOnlyCount: sample.pingSuccess == null ? 1 : 0,
            newestSample: sample,
            samples: [sample],
          ),
        )
        .toList();
    clusters.sort(
      (a, b) => a.newestSample.timestamp.compareTo(b.newestSample.timestamp),
    );
    return clusters;
  }

  static String _keyAtPrecision(
    String existingHash,
    double latitude,
    double longitude,
    int precision,
  ) {
    if (existingHash.length >= precision) {
      return existingHash.substring(0, precision);
    }
    return GeohashUtils.coverageKey(latitude, longitude, precision: precision);
  }

  static DateTime? _latest(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null || first.isAfter(second)) return first;
    return second;
  }
}

class SampleCluster {
  final String id;
  final LatLng position;
  final int sampleCount;
  final int successfulCount;
  final int failedCount;
  final int gpsOnlyCount;
  final Sample newestSample;

  /// Every measurement in this cluster, so detail views can list them all.
  final List<Sample> samples;

  const SampleCluster({
    required this.id,
    required this.position,
    required this.sampleCount,
    required this.successfulCount,
    required this.failedCount,
    required this.gpsOnlyCount,
    required this.newestSample,
    this.samples = const [],
  });
}

class _CoverageBucket {
  double received = 0;
  double lost = 0;
  DateTime? lastReceived;
  DateTime? updated;
  final Set<String> repeaters = {};
}

class _SampleBucket {
  int sampleCount = 0;
  double latitudeSum = 0;
  double longitudeSum = 0;
  int successfulCount = 0;
  int failedCount = 0;
  int gpsOnlyCount = 0;
  Sample? newestSample;
  final List<Sample> samples = [];

  /// Average position of the member samples.
  LatLng get centroid =>
      LatLng(latitudeSum / sampleCount, longitudeSum / sampleCount);

  void add(Sample sample) {
    sampleCount++;
    latitudeSum += sample.position.latitude;
    longitudeSum += sample.position.longitude;
    samples.add(sample);
    if (sample.pingSuccess == true) {
      successfulCount++;
    } else if (sample.pingSuccess == false) {
      failedCount++;
    } else {
      gpsOnlyCount++;
    }

    if (newestSample == null ||
        sample.timestamp.isAfter(newestSample!.timestamp)) {
      newestSample = sample;
    }
  }
}
