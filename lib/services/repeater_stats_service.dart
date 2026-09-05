import 'dart:math';

import '../models/models.dart';
import '../utils/geohash_utils.dart';

/// Aggregated reliability statistics for one repeater, computed from the
/// samples recorded for it. Rendered by both the Analytics screen and the
/// Repeater Health screen.
class RepeaterStats {
  final String id;
  final int totalPings;
  final int successCount;
  final double responseRate;

  /// Average ping response time in milliseconds, null without response data.
  final double? avgResponseMs;

  /// Standard deviation of the response times, null when none were recorded.
  final double? responseStddevMs;

  /// 'improving', 'stable', or 'degrading' — compares the success rate of the
  /// last 7 days with the success rate of the last 30 days.
  final String trend;
  final bool isDegrading;
  final bool isOffline;
  final int daysSinceSeen;
  final double? rate7day;
  final double? rate30day;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int coverageCells;

  const RepeaterStats({
    required this.id,
    required this.totalPings,
    required this.successCount,
    required this.responseRate,
    this.avgResponseMs,
    this.responseStddevMs,
    required this.trend,
    this.isDegrading = false,
    this.isOffline = false,
    this.daysSinceSeen = 0,
    this.rate7day,
    this.rate30day,
    required this.firstSeen,
    required this.lastSeen,
    required this.coverageCells,
  });
}

/// Computes [RepeaterStats] from recorded samples.
class RepeaterStatsService {
  RepeaterStatsService._();

  /// Minimum samples for a trend window to be classified.
  static const int _minWindowSamples = 3;

  /// Groups samples that carry a ping outcome and a known repeater path by
  /// that path.
  static Map<String, List<Sample>> groupByRepeater(List<Sample> samples) {
    final Map<String, List<Sample>> map = {};
    for (final s in samples) {
      if (s.pingSuccess != null && s.path != null && s.path!.isNotEmpty) {
        map.putIfAbsent(s.path!, () => []).add(s);
      }
    }
    return map;
  }

  /// Computes the statistics for one repeater from its [samples]. The list is
  /// not modified and must not be empty.
  static RepeaterStats compute(
    String id,
    List<Sample> samples, {
    DateTime? now,
  }) {
    assert(samples.isNotEmpty);
    final effectiveNow = now ?? DateTime.now();
    final successes = samples.where((s) => s.pingSuccess == true).length;
    final totalPings = samples.length;
    final responseRate = totalPings > 0 ? successes / totalPings : 0.0;

    // Response times
    final responseTimes = samples
        .where((s) => s.responseTimeMs != null)
        .map((s) => s.responseTimeMs!.toDouble())
        .toList();

    double? avgResponse;
    double? stddev;
    if (responseTimes.isNotEmpty) {
      avgResponse =
          responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      final variance =
          responseTimes
              .map((t) => (t - avgResponse!) * (t - avgResponse))
              .reduce((a, b) => a + b) /
          responseTimes.length;
      stddev = sqrt(variance);
    }

    // Trend: success rate of the last 7 days versus the last 30 days.
    final sevenDays = effectiveNow.subtract(const Duration(days: 7));
    final thirtyDays = effectiveNow.subtract(const Duration(days: 30));
    final recent7 = samples
        .where((s) => s.timestamp.isAfter(sevenDays))
        .toList();
    final recent30 = samples
        .where((s) => s.timestamp.isAfter(thirtyDays))
        .toList();

    double? rate7;
    double? rate30;
    if (recent7.length >= _minWindowSamples) {
      rate7 =
          recent7.where((s) => s.pingSuccess == true).length / recent7.length;
    }
    if (recent30.length >= _minWindowSamples) {
      rate30 =
          recent30.where((s) => s.pingSuccess == true).length / recent30.length;
    }

    String trend = 'stable';
    var isDegrading = false;
    if (rate7 != null && rate30 != null) {
      if (rate7 - rate30 > 0.1) {
        trend = 'improving';
      } else if (rate30 - rate7 > 0.15) {
        trend = 'degrading';
        isDegrading = true;
      }
    }

    var firstSeen = samples.first.timestamp;
    var lastSeen = samples.first.timestamp;
    for (final s in samples) {
      if (s.timestamp.isBefore(firstSeen)) firstSeen = s.timestamp;
      if (s.timestamp.isAfter(lastSeen)) lastSeen = s.timestamp;
    }

    final coverageCells = <String>{
      for (final s in samples) GeohashUtils.truncate(s.geohash, 6),
    };

    final daysSinceSeen = effectiveNow.difference(lastSeen).inDays;

    return RepeaterStats(
      id: id,
      totalPings: totalPings,
      successCount: successes,
      responseRate: responseRate,
      avgResponseMs: avgResponse,
      responseStddevMs: stddev,
      trend: trend,
      isDegrading: isDegrading,
      isOffline: daysSinceSeen >= 7 && totalPings >= 10,
      daysSinceSeen: daysSinceSeen,
      rate7day: rate7,
      rate30day: rate30,
      firstSeen: firstSeen,
      lastSeen: lastSeen,
      coverageCells: coverageCells.length,
    );
  }
}
