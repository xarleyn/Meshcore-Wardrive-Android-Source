import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/services/aggregation_service.dart';

void main() {
  group('AggregationService', () {
    test('uses the same lookup key for full and short repeater IDs', () {
      const shortNodeId = 'aabbccdd';
      const fullNodeId =
          'AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899';

      expect(
        AggregationService.repeaterLookupKey(fullNodeId),
        AggregationService.repeaterLookupKey(shortNodeId),
      );
    });

    test('links a full sample node ID to its short repeater ID', () {
      const shortNodeId = 'AABBCCDD';
      const fullNodeId =
          'AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899';
      final repeater = Repeater(
        id: shortNodeId,
        position: const LatLng(55.75, 37.62),
      );
      final sample = Sample(
        id: 'sample-1',
        position: const LatLng(55.76, 37.63),
        timestamp: DateTime.now(),
        path: fullNodeId,
        geohash: 'ucftpv12',
        pingSuccess: true,
      );

      final result = AggregationService.buildIndexes([sample], [repeater]);

      expect(result.coverages.single.repeaters, [fullNodeId]);
      expect(result.edges, hasLength(1));
      expect(result.edges.single.repeater, same(repeater));
    });

    test('matches repeater IDs without case sensitivity', () {
      final repeater = Repeater(
        id: 'aabbccdd',
        position: const LatLng(55.75, 37.62),
      );
      final sample = Sample(
        id: 'sample-1',
        position: const LatLng(55.76, 37.63),
        timestamp: DateTime.now(),
        path: 'AABBCCDDEEFF0011',
        geohash: 'ucftpv12',
        pingSuccess: true,
      );

      final result = AggregationService.buildIndexes([sample], [repeater]);

      expect(result.edges.single.repeater, same(repeater));
    });
  });

  group('AggregationService optimistic display', () {
    final now = DateTime.now();
    late Repeater repeater;

    setUp(() {
      repeater = Repeater(id: 'AABBCCDD', position: const LatLng(55.75, 37.62));
    });

    Sample ping(String id, DateTime timestamp, bool success) => Sample(
      id: id,
      position: const LatLng(55.76, 37.63),
      timestamp: timestamp,
      geohash: 'ucftpv12',
      pingSuccess: success,
    );

    test('off by default keeps failed pings in the cell', () {
      final result = AggregationService.buildIndexes(
        [
          ping('success', now.subtract(const Duration(hours: 2)), true),
          ping('failure', now, false),
        ],
        [repeater],
      );

      expect(result.coverages.single.received, greaterThan(0));
      expect(result.coverages.single.lost, greaterThan(0));
    });

    test('a fresh success ignores later failed pings', () {
      final result = AggregationService.buildIndexes(
        [
          ping('success', now.subtract(const Duration(days: 2)), true),
          ping('failure', now, false),
        ],
        [repeater],
        optimisticDisplay: true,
      );

      expect(result.coverages.single.received, greaterThan(0));
      expect(result.coverages.single.lost, 0);
    });

    test('any success counts even when failures dominate', () {
      final samples = [
        for (var i = 0; i < 5; i++)
          ping('failure-$i', now.subtract(Duration(minutes: i)), false),
        ping('success', now.subtract(const Duration(days: 1)), true),
      ];

      final result = AggregationService.buildIndexes(samples, [
        repeater,
      ], optimisticDisplay: true);

      expect(result.coverages.single.lost, 0);
    });

    test('a month-old success loses to newer failures', () {
      final result = AggregationService.buildIndexes(
        [
          ping('stale-success', now.subtract(const Duration(days: 31)), true),
          ping('failure', now, false),
        ],
        [repeater],
        optimisticDisplay: true,
      );

      expect(result.coverages.single.lost, greaterThan(0));
    });

    test('a success just inside the staleness window still wins', () {
      final result = AggregationService.buildIndexes(
        [
          ping('success', now.subtract(const Duration(days: 30)), true),
          ping('failure', now, false),
        ],
        [repeater],
        optimisticDisplay: true,
      );

      expect(result.coverages.single.lost, 0);
    });

    test('a failure older than the success does not break the cell', () {
      // The ping failed before the cell was successfully reached; the
      // later success reflects the current state better.
      final result = AggregationService.buildIndexes(
        [
          ping('failure', now.subtract(const Duration(days: 40)), false),
          ping('old-success', now.subtract(const Duration(days: 35)), true),
        ],
        [repeater],
        optimisticDisplay: true,
      );

      expect(result.coverages.single.lost, 0);
    });
  });
}
