import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/utils/ping_success_stats.dart';

Sample _sample(String id, {bool? pingSuccess}) {
  return Sample(
    id: id,
    position: const LatLng(1, 2),
    timestamp: DateTime(2026, 9, 1, 12),
    geohash: 'ucftu',
    pingSuccess: pingSuccess,
  );
}

void main() {
  group('PingSuccessStats.of', () {
    test('counts only samples with a ping outcome', () {
      final stats = PingSuccessStats.of([
        _sample('a', pingSuccess: true),
        _sample('b', pingSuccess: true),
        _sample('c', pingSuccess: false),
        _sample('d'),
      ]);

      expect(stats.pinged, 3);
      expect(stats.success, 2);
      expect(stats.failed, 1);
    });

    test('ratePercent rounds to whole percents', () {
      final stats = PingSuccessStats.of([
        _sample('a', pingSuccess: true),
        _sample('b', pingSuccess: true),
        _sample('c', pingSuccess: false),
      ]);

      expect(stats.ratePercent, '67%');
    });

    test('ratePercent is null when nothing pinged', () {
      expect(PingSuccessStats.of([_sample('a')]).ratePercent, isNull);
      expect(PingSuccessStats.of(const <Sample>[]).ratePercent, isNull);
      expect(PingSuccessStats.of(const <Sample>[]).pinged, 0);
    });
  });
}
