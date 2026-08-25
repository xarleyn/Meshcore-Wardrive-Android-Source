import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/services/map_lod_service.dart';

void main() {
  group('MapLodService', () {
    test('changes precision only at two-level zoom boundaries', () {
      expect(MapLodService.precisionForZoom(5, maxPrecision: 8), 3);
      expect(MapLodService.precisionForZoom(7.9, maxPrecision: 8), 3);
      expect(MapLodService.precisionForZoom(8, maxPrecision: 8), 4);
      expect(MapLodService.precisionForZoom(13.9, maxPrecision: 8), 6);
      expect(MapLodService.precisionForZoom(18, maxPrecision: 7), 7);
    });

    test('merges coverage statistics and repeater IDs', () {
      final older = DateTime.utc(2026, 1, 1);
      final newer = DateTime.utc(2026, 2, 1);
      final coverages = [
        Coverage(
          id: 'ucftpv1',
          position: const LatLng(55.75, 37.61),
          received: 2,
          lost: 1,
          lastReceived: older,
          updated: older,
          repeaters: ['A', 'B'],
        ),
        Coverage(
          id: 'ucftpv2',
          position: const LatLng(55.75, 37.62),
          received: 3,
          lost: 4,
          lastReceived: newer,
          updated: newer,
          repeaters: ['B', 'C'],
        ),
      ];

      final result = MapLodService.aggregateCoverages(coverages, precision: 6);

      expect(result, hasLength(1));
      expect(result.single.id, 'ucftpv');
      expect(result.single.received, 5);
      expect(result.single.lost, 5);
      expect(result.single.lastReceived, newer);
      expect(result.single.updated, newer);
      expect(result.single.repeaters, unorderedEquals(['A', 'B', 'C']));
    });

    test('deduplicates edges in the same coarse cell', () {
      final repeater = Repeater(
        id: 'aabbccdd',
        position: const LatLng(55.8, 37.7),
      );
      final first = Coverage(
        id: 'ucftpv1',
        position: const LatLng(55.75, 37.61),
      );
      final second = Coverage(
        id: 'ucftpv2',
        position: const LatLng(55.75, 37.62),
      );
      final lodCoverages = MapLodService.aggregateCoverages([
        first,
        second,
      ], precision: 6);

      final result = MapLodService.aggregateEdges(
        [
          Edge(coverage: first, repeater: repeater),
          Edge(coverage: second, repeater: repeater),
        ],
        lodCoverages,
        precision: 6,
      );

      expect(result, hasLength(1));
      expect(result.single.coverage, same(lodCoverages.single));
    });

    test('aggregates sample result counts and keeps the newest sample', () {
      final older = Sample(
        id: 'old',
        position: const LatLng(55.75, 37.61),
        timestamp: DateTime.utc(2026, 1, 1),
        geohash: 'ucftpv11',
        pingSuccess: true,
      );
      final newer = Sample(
        id: 'new',
        position: const LatLng(55.75, 37.62),
        timestamp: DateTime.utc(2026, 2, 1),
        geohash: 'ucftpv22',
        pingSuccess: false,
      );
      final gpsOnly = Sample(
        id: 'gps',
        position: const LatLng(55.75, 37.63),
        timestamp: DateTime.utc(2026, 1, 15),
        geohash: 'ucftpv33',
      );

      final result = MapLodService.aggregateSamples([
        older,
        newer,
        gpsOnly,
      ], precision: 6);

      expect(result, hasLength(1));
      expect(result.single.sampleCount, 3);
      expect(result.single.successfulCount, 1);
      expect(result.single.failedCount, 1);
      expect(result.single.gpsOnlyCount, 1);
      expect(result.single.newestSample, same(newer));
      // The cluster keeps every measurement so details can be listed.
      expect(result.single.samples, unorderedEquals([older, newer, gpsOnly]));
    });

    test('keeps each sample at its GPS position when LOD is off', () {
      final first = Sample(
        id: 'a',
        position: const LatLng(55.75, 37.61),
        timestamp: DateTime.utc(2026, 1, 1),
        geohash: 'ucftpv11',
        pingSuccess: true,
      );
      final second = Sample(
        id: 'b',
        position: const LatLng(55.76, 37.62),
        timestamp: DateTime.utc(2026, 2, 1),
        geohash: 'ucftpv11',
        pingSuccess: false,
      );

      final result = MapLodService.individualSamples([second, first]);

      expect(result, hasLength(2));
      expect(result.first.newestSample, same(first));
      expect(result.first.position, first.position);
      expect(result.first.sampleCount, 1);
      expect(result.first.successfulCount, 1);
      expect(result.first.samples, [first]);
      expect(result.last.newestSample, same(second));
      expect(result.last.position, second.position);
      expect(result.last.failedCount, 1);
      expect(result.last.samples, [second]);
    });
  });
}
