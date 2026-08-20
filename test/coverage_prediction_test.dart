import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/utils/coverage_prediction.dart';

void main() {
  const distance = Distance();
  const center = LatLng(55.75, 37.62);

  Sample sampleAtDistance(
    String id,
    double distanceMeters, {
    String? path = 'AABBCCDDEEFF00112233445566778899',
    bool? pingSuccess = true,
  }) {
    return Sample(
      id: id,
      position: distance.offset(center, distanceMeters, 90),
      timestamp: DateTime(2025),
      path: path,
      geohash: 'ucftpv12',
      pingSuccess: pingSuccess,
    );
  }

  group('buildCoveragePredictionRings', () {
    test('builds percentile rings and matches full paths to short IDs', () {
      final repeater = Repeater(id: 'aabbccdd', position: center);
      final samples = <Sample>[
        sampleAtDistance('1', 100),
        sampleAtDistance('2', 200),
        sampleAtDistance('3', 300),
        sampleAtDistance('4', 400),
        sampleAtDistance('5', 500),
        sampleAtDistance('6', 600),
        sampleAtDistance('7', 700),
        sampleAtDistance('8', 1000),
      ];

      final rings = buildCoveragePredictionRings(
        samples: samples,
        repeaters: [repeater],
      );

      expect(rings.map((ring) => ring.kind), [
        CoveragePredictionRingKind.edge,
        CoveragePredictionRingKind.moderate,
        CoveragePredictionRingKind.strong,
      ]);
      expect(rings.every((ring) => ring.center == center), isTrue);
      expect(rings[0].radiusMeters, closeTo(1000, 1));
      expect(rings[1].radiusMeters, closeTo(700, 1));
      expect(rings[2].radiusMeters, closeTo(300, 1));
    });

    test('applies case-insensitive repeater prefix whitelist', () {
      final included = Repeater(id: 'AABBCCDD', position: center);
      final excluded = Repeater(
        id: 'EEFF0011',
        position: const LatLng(55.8, 37.7),
      );
      final unknown = Repeater(id: 'AABB0000', position: const LatLng(0, 0));
      final samples = <Sample>[
        sampleAtDistance('1', 60),
        sampleAtDistance('2', 70),
        sampleAtDistance('3', 80),
      ];

      final rings = buildCoveragePredictionRings(
        samples: samples,
        repeaters: [included, excluded, unknown],
        includeOnlyRepeaters: ' aaBB ',
      );

      expect(rings, isNotEmpty);
      expect(rings.every((ring) => ring.center == center), isTrue);
    });

    test('requires three usable successful observations', () {
      final repeater = Repeater(id: 'AABBCCDD', position: center);
      final samples = <Sample>[
        sampleAtDistance('valid-1', 60),
        sampleAtDistance('valid-2', 70),
        sampleAtDistance('failed', 80, pingSuccess: false),
        sampleAtDistance('gps-only', 90, pingSuccess: null),
        sampleAtDistance('missing-path', 100, path: null),
        sampleAtDistance('empty-path', 110, path: ''),
        sampleAtDistance('wrong-path', 120, path: 'DEADBEEF'),
        sampleAtDistance('over-cap', 100001),
      ];

      final rings = buildCoveragePredictionRings(
        samples: samples,
        repeaters: [repeater],
      );

      expect(rings, isEmpty);
    });

    test('omits tiny and insufficiently separated inner rings', () {
      final repeater = Repeater(id: 'AABBCCDD', position: center);

      final tiny = buildCoveragePredictionRings(
        samples: [
          sampleAtDistance('1', 20),
          sampleAtDistance('2', 30),
          sampleAtDistance('3', 49),
        ],
        repeaters: [repeater],
      );
      final sameRadius = buildCoveragePredictionRings(
        samples: [
          sampleAtDistance('4', 60),
          sampleAtDistance('5', 60),
          sampleAtDistance('6', 60),
        ],
        repeaters: [repeater],
      );

      expect(tiny, isEmpty);
      expect(sameRadius, hasLength(1));
      expect(sameRadius.single.kind, CoveragePredictionRingKind.edge);
    });
  });
}
