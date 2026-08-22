import 'package:flutter_test/flutter_test.dart';
import 'package:geohash_plus/geohash_plus.dart' as geohash;
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/utils/community_coverage.dart';
import 'package:meshcore_wardrive/utils/geohash_utils.dart';

void main() {
  group('CommunityCoverage', () {
    test('aggregates sibling cells to the requested precision', () {
      final aggregated = CommunityCoverage.aggregate({
        'ucftpv1': {
          'received': 2,
          'lost': 1,
          'samples': 3,
          'repeaters': {
            'aa': {'name': 'A', 'lastSeen': '2026-01-01T00:00:00.000Z'},
          },
          'lastUpdate': '2026-01-01T00:00:00.000Z',
          'appVersion': '1.0.0',
        },
        'ucftpv2': {
          'received': 3,
          'lost': 4,
          'samples': 7,
          'repeaters': {
            'aa': {'name': 'A-later', 'lastSeen': '2026-02-01T00:00:00.000Z'},
            'bb': {'name': 'B', 'lastSeen': '2026-01-15T00:00:00.000Z'},
          },
          'lastUpdate': '2026-02-01T00:00:00.000Z',
          'appVersion': '1.0.1',
        },
      }, precision: 6);

      expect(aggregated.keys, ['ucftpv']);
      final cell = aggregated['ucftpv']!;
      expect(cell.received, 5);
      expect(cell.lost, 5);
      expect(cell.samples, 10);
      expect(cell.lastUpdate, '2026-02-01T00:00:00.000Z');
      expect(cell.repeaters['aa']['name'], 'A-later');
      expect(cell.repeaters['bb']['name'], 'B');
    });

    test('keeps coarser cells instead of dropping them', () {
      final aggregated = CommunityCoverage.aggregate({
        'ucft': {
          'received': 1,
          'lost': 0,
          'samples': 1,
          'lastUpdate': '2026-01-01T00:00:00.000Z',
        },
        'ucftpv1': {
          'received': 2,
          'lost': 0,
          'samples': 2,
          'lastUpdate': '2026-01-02T00:00:00.000Z',
        },
      }, precision: 6);

      expect(aggregated.keys, unorderedEquals(['ucft', 'ucftpv']));
      expect(aggregated['ucft']!.received, 1);
      expect(aggregated['ucftpv']!.received, 2);
    });

    test('uses exact geohash bounds for polygons and hit testing', () {
      final hash = GeohashUtils.coverageKey(47.7776, -122.4247, precision: 7);
      final decoded = geohash.GeoHash.decode(hash);
      final aggregated = CommunityCoverage.aggregate({
        hash: {'received': 1, 'lost': 0, 'samples': 1},
      }, precision: 7);
      final cell = aggregated[hash]!;

      expect(cell.southWest.latitude, decoded.bounds.southWest.latitude);
      expect(cell.southWest.longitude, decoded.bounds.southWest.longitude);
      expect(cell.northEast.latitude, decoded.bounds.northEast.latitude);
      expect(cell.northEast.longitude, decoded.bounds.northEast.longitude);
      expect(cell.polygonPoints, [
        LatLng(
          decoded.bounds.southWest.latitude,
          decoded.bounds.southWest.longitude,
        ),
        LatLng(
          decoded.bounds.southWest.latitude,
          decoded.bounds.northEast.longitude,
        ),
        LatLng(
          decoded.bounds.northEast.latitude,
          decoded.bounds.northEast.longitude,
        ),
        LatLng(
          decoded.bounds.northEast.latitude,
          decoded.bounds.southWest.longitude,
        ),
      ]);
      expect(cell.contains(GeohashUtils.posFromHash(hash)), isTrue);
      expect(cell.contains(const LatLng(0, 0)), isFalse);
    });

    test('hit-tests the same aggregated cells used for rendering', () {
      final fine = GeohashUtils.coverageKey(47.7776, -122.4247, precision: 7);
      final coarse = fine.substring(0, 5);
      final cells = CommunityCoverage.aggregate({
        fine: {'received': 1, 'lost': 0, 'samples': 1},
        coarse: {'received': 8, 'lost': 2, 'samples': 10},
      }, precision: 7);
      final point = GeohashUtils.posFromHash(fine);

      final hit = CommunityCoverage.hitTest(cells, point);

      expect(hit?.hash, fine);
    });

    test('culls cells that do not intersect the viewport', () {
      final hash = GeohashUtils.coverageKey(47.7776, -122.4247, precision: 7);
      final cells = CommunityCoverage.aggregate({
        hash: {'received': 1, 'lost': 0, 'samples': 1},
      }, precision: 7);
      final cell = cells[hash]!;

      expect(
        cell.intersectsViewport(
          south: 47.7,
          north: 47.8,
          west: -122.5,
          east: -122.3,
        ),
        isTrue,
      );
      expect(
        cell.intersectsViewport(south: 0, north: 1, west: 0, east: 1),
        isFalse,
      );
    });
  });
}
