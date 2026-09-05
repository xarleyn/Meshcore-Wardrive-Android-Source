import 'package:geohash_plus/geohash_plus.dart' as geohash;

import 'geohash_utils.dart';

import 'package:latlong2/latlong.dart';

class CommunityCoverageCell {
  CommunityCoverageCell({
    required this.hash,
    required this.received,
    required this.lost,
    required this.samples,
    required this.repeaters,
    required this.lastUpdate,
    required this.appVersion,
    required this.southWest,
    required this.northEast,
  });

  final String hash;
  final double received;
  final double lost;
  final int samples;
  final Map<String, dynamic> repeaters;
  final String lastUpdate;
  final String appVersion;
  final LatLng southWest;
  final LatLng northEast;

  List<LatLng> get polygonPoints => [
    LatLng(southWest.latitude, southWest.longitude),
    LatLng(southWest.latitude, northEast.longitude),
    LatLng(northEast.latitude, northEast.longitude),
    LatLng(northEast.latitude, southWest.longitude),
  ];

  bool contains(LatLng point) {
    return point.latitude >= southWest.latitude &&
        point.latitude <= northEast.latitude &&
        point.longitude >= southWest.longitude &&
        point.longitude <= northEast.longitude;
  }

  bool intersectsViewport({
    required double south,
    required double north,
    required double west,
    required double east,
  }) {
    return !(south > northEast.latitude ||
        north < southWest.latitude ||
        west > northEast.longitude ||
        east < southWest.longitude);
  }
}

class CommunityCoverage {
  const CommunityCoverage._();

  static Map<String, CommunityCoverageCell> aggregate(
    Map<String, dynamic> raw, {
    required int precision,
  }) {
    final aggregated = <String, _CommunityCellAccumulator>{};

    raw.forEach((hash, cellData) {
      if (cellData is! Map<String, dynamic> || hash.isEmpty) return;
      final key = GeohashUtils.truncate(hash, precision);
      final acc = aggregated.putIfAbsent(key, _CommunityCellAccumulator.new);
      acc.add(cellData);
    });

    final cells = <String, CommunityCoverageCell>{};
    for (final entry in aggregated.entries) {
      final cell = _cellFromHash(entry.key, entry.value);
      if (cell != null) {
        cells[entry.key] = cell;
      }
    }
    return cells;
  }

  static CommunityCoverageCell? hitTest(
    Map<String, CommunityCoverageCell> cells,
    LatLng point,
  ) {
    CommunityCoverageCell? best;
    for (final cell in cells.values) {
      if (!cell.contains(point)) continue;
      if (best == null || cell.hash.length > best.hash.length) {
        best = cell;
      }
    }
    return best;
  }

  static CommunityCoverageCell? _cellFromHash(
    String hash,
    _CommunityCellAccumulator acc,
  ) {
    try {
      final decoded = geohash.GeoHash.decode(hash);
      return CommunityCoverageCell(
        hash: hash,
        received: acc.received,
        lost: acc.lost,
        samples: acc.samples,
        repeaters: acc.repeaters,
        lastUpdate: acc.lastUpdate,
        appVersion: acc.appVersion,
        southWest: LatLng(
          decoded.bounds.southWest.latitude,
          decoded.bounds.southWest.longitude,
        ),
        northEast: LatLng(
          decoded.bounds.northEast.latitude,
          decoded.bounds.northEast.longitude,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

class _CommunityCellAccumulator {
  double received = 0;
  double lost = 0;
  int samples = 0;
  final Map<String, dynamic> repeaters = {};
  String lastUpdate = '';
  String appVersion = 'unknown';

  void add(Map<String, dynamic> cellData) {
    received += (cellData['received'] as num?)?.toDouble() ?? 0;
    lost += (cellData['lost'] as num?)?.toDouble() ?? 0;
    samples += (cellData['samples'] as num?)?.toInt() ?? 0;
    appVersion = cellData['appVersion'] as String? ?? appVersion;

    final reps = cellData['repeaters'];
    if (reps is Map<String, dynamic>) {
      reps.forEach((nodeId, rep) {
        if (rep is! Map<String, dynamic>) return;
        final existing = repeaters[nodeId];
        if (existing is! Map<String, dynamic> ||
            (rep['lastSeen'] ?? '').toString().compareTo(
                  (existing['lastSeen'] ?? '').toString(),
                ) >
                0) {
          repeaters[nodeId] = rep;
        }
      });
    }

    final cellUpdate = cellData['lastUpdate'] as String? ?? '';
    if (cellUpdate.compareTo(lastUpdate) > 0) {
      lastUpdate = cellUpdate;
    }
  }
}
