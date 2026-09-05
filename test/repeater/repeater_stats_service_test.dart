import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/services/repeater_stats_service.dart';

Sample _sample(
  DateTime timestamp, {
  bool? pingSuccess = true,
  int? responseTimeMs,
  String? path = 'REP1',
  String geohash = 'u2m12345',
}) {
  return Sample(
    id: '${timestamp.millisecondsSinceEpoch}-$responseTimeMs',
    position: const LatLng(47.7, -122.4),
    timestamp: timestamp,
    path: path,
    geohash: geohash,
    pingSuccess: pingSuccess,
    responseTimeMs: responseTimeMs,
  );
}

void main() {
  final now = DateTime(2026, 9, 5, 12);

  group('groupByRepeater', () {
    test('groups samples by path and drops unusable rows', () {
      final samples = [
        _sample(now, path: 'AAA'),
        _sample(now, path: 'BBB'),
        _sample(now, path: 'AAA'),
        _sample(now, path: null),
        _sample(now, path: ''),
        _sample(now, pingSuccess: null),
      ];

      final grouped = RepeaterStatsService.groupByRepeater(samples);

      expect(grouped.keys, containsAll(['AAA', 'BBB']));
      expect(grouped['AAA'], hasLength(2));
      expect(grouped['BBB'], hasLength(1));
    });
  });

  group('compute', () {
    test('computes response rate and response-time statistics', () {
      final stats = RepeaterStatsService.compute('AAA', [
        _sample(now, pingSuccess: true, responseTimeMs: 100),
        _sample(now, pingSuccess: true, responseTimeMs: 200),
        _sample(now, pingSuccess: false),
      ], now: now);

      expect(stats.id, 'AAA');
      expect(stats.totalPings, 3);
      expect(stats.successCount, 2);
      expect(stats.responseRate, closeTo(2 / 3, 0.0001));
      expect(stats.avgResponseMs, closeTo(150, 0.0001));
      expect(stats.responseStddevMs, closeTo(50, 0.0001));
    });

    test('counts unique coverage cells at precision 6', () {
      final stats = RepeaterStatsService.compute('AAA', [
        _sample(now, geohash: 'u2m12345'),
        _sample(now, geohash: 'u2m12378'),
        _sample(now, geohash: 'u2m91234'),
      ], now: now);

      expect(stats.coverageCells, 2);
    });

    test('marks degrading trend when recent week underperforms 30 days', () {
      final stats = RepeaterStatsService.compute('AAA', [
        // 30-day window: 10 pings, 9 successes (0.9).
        for (var i = 0; i < 6; i++)
          _sample(now.subtract(Duration(days: 20 + i)), pingSuccess: true),
        for (var i = 0; i < 3; i++)
          _sample(now.subtract(Duration(days: 25 + i)), pingSuccess: true),
        // Last 7 days: 3 pings, all failures (0.0).
        for (var i = 0; i < 3; i++)
          _sample(now.subtract(Duration(days: i + 1)), pingSuccess: false),
      ], now: now);

      expect(stats.trend, 'degrading');
      expect(stats.isDegrading, isTrue);
    });

    test('marks improving trend when recent week outperforms 30 days', () {
      final stats = RepeaterStatsService.compute('AAA', [
        // 30-day window: 10 pings, 1 success (0.1).
        for (var i = 0; i < 9; i++)
          _sample(now.subtract(Duration(days: 20 + i)), pingSuccess: false),
        _sample(now.subtract(Duration(days: 28)), pingSuccess: true),
        // Last 7 days: 3 pings, all successes (1.0).
        for (var i = 0; i < 3; i++)
          _sample(now.subtract(Duration(days: i + 1)), pingSuccess: true),
      ], now: now);

      expect(stats.trend, 'improving');
    });

    test('stays stable with too few samples in the windows', () {
      final stats = RepeaterStatsService.compute('AAA', [
        _sample(now.subtract(const Duration(days: 1)), pingSuccess: false),
        _sample(now.subtract(const Duration(days: 2)), pingSuccess: false),
      ], now: now);

      expect(stats.trend, 'stable');
      expect(stats.isDegrading, isFalse);
      expect(stats.rate7day, isNull);
      expect(stats.rate30day, isNull);
    });

    test('flags offline repeaters not seen for a week with enough pings', () {
      final samples = [
        for (var i = 0; i < 12; i++)
          _sample(now.subtract(Duration(days: 8 + i)), pingSuccess: true),
      ];
      final stats = RepeaterStatsService.compute('AAA', samples, now: now);

      expect(stats.isOffline, isTrue);
      expect(stats.daysSinceSeen, greaterThanOrEqualTo(8));
    });

    test('reports first and last seen regardless of input order', () {
      final stats = RepeaterStatsService.compute('AAA', [
        _sample(now.subtract(const Duration(days: 30))),
        _sample(now.subtract(const Duration(days: 1))),
        _sample(now.subtract(const Duration(days: 10))),
      ], now: now);

      expect(stats.firstSeen, now.subtract(const Duration(days: 30)));
      expect(stats.lastSeen, now.subtract(const Duration(days: 1)));
    });
  });
}
