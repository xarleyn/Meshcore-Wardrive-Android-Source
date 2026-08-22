import '../models/location_quality_settings.dart';

/// Tracks consecutive rejected location fixes and reports whether automatic
/// pings should pause until a trustworthy fix arrives.
///
/// A single accepted fix clears the streak, so "the last N measurements are
/// incorrect" and "N consecutive rejections" are the same condition. The
/// threshold is mutable so a live settings change immediately affects the
/// pause state computed from the already-recorded streak.
class BadFixMonitor {
  BadFixMonitor({
    this.requiredBadFixes = LocationQualitySettings.defaultPingPauseBadFixCount,
  });

  /// Rejections in a row needed to pause. Values below the configured minimum
  /// are treated as the minimum so the monitor can always engage.
  int requiredBadFixes;

  int _consecutiveBadFixes = 0;

  int get consecutiveBadFixes => _consecutiveBadFixes;

  bool get isPaused {
    final threshold =
        requiredBadFixes < LocationQualitySettings.minPingPauseBadFixCount
        ? LocationQualitySettings.minPingPauseBadFixCount
        : requiredBadFixes;
    return _consecutiveBadFixes >= threshold;
  }

  void recordRejectedFix() {
    _consecutiveBadFixes += 1;
  }

  void recordAcceptedFix() {
    _consecutiveBadFixes = 0;
  }

  void reset() {
    _consecutiveBadFixes = 0;
  }
}
