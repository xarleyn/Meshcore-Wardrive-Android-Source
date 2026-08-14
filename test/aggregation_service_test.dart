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
}
