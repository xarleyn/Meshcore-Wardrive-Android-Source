import '../models/models.dart';

/// Outcome counts over samples that recorded a ping result.
///
/// Samples without a ping outcome (GPS-only fixes) are ignored.
class PingSuccessStats {
  const PingSuccessStats({
    required this.pinged,
    required this.success,
    required this.failed,
  });

  final int pinged;
  final int success;
  final int failed;

  /// Rounded success-rate percentage (`'42%'`), or null when nothing pinged.
  String? get ratePercent =>
      pinged == 0 ? null : '${(success / pinged * 100).toStringAsFixed(0)}%';

  /// Tallies [samples] by their ping outcome.
  factory PingSuccessStats.of(Iterable<Sample> samples) {
    var pinged = 0;
    var success = 0;
    var failed = 0;
    for (final sample in samples) {
      final outcome = sample.pingSuccess;
      if (outcome == null) continue;
      pinged++;
      outcome ? success++ : failed++;
    }
    return PingSuccessStats(pinged: pinged, success: success, failed: failed);
  }
}
