import 'heading_utils.dart';

enum CompassAccuracyStatus { unknown, reliable, needsCalibration }

class CompassCalibrationPolicy {
  const CompassCalibrationPolicy._();

  /// Ignore the plugin's default UNRELIABLE status until it has lasted this long.
  static const Duration unreliableHold = Duration(seconds: 3);

  /// After Later / skip, do not show the map banner again until this elapses.
  static const Duration snoozeDuration = Duration(hours: 24);

  /// After a finished figure-8, stay quiet briefly even if accuracy flickers.
  static const Duration postSuccessQuietDuration = Duration(hours: 1);

  static bool isReliable(double? accuracy) {
    return accuracy != null && accuracy <= 30;
  }

  static bool isUnreliable(double? accuracy) {
    return accuracy == null || accuracy >= 45;
  }

  static bool shouldShowBanner({
    required CompassAccuracyStatus status,
    required bool compassInUse,
    required DateTime now,
    DateTime? quietUntil,
  }) {
    if (!compassInUse) return false;
    if (status != CompassAccuracyStatus.needsCalibration) return false;
    if (quietUntil != null && !now.isAfter(quietUntil)) return false;
    return true;
  }
}

/// Debounces flutter_compass accuracy so a cold start does not nag immediately.
class CompassAccuracyMonitor {
  CompassAccuracyStatus _status = CompassAccuracyStatus.unknown;
  DateTime? _unreliableSince;

  CompassAccuracyStatus get status => _status;

  void reset() {
    _status = CompassAccuracyStatus.unknown;
    _unreliableSince = null;
  }

  CompassAccuracyStatus observe({
    required DateTime now,
    double? heading,
    double? accuracy,
  }) {
    if (heading == null || !heading.isFinite) return _status;

    if (CompassCalibrationPolicy.isReliable(accuracy)) {
      _unreliableSince = null;
      _status = CompassAccuracyStatus.reliable;
      return _status;
    }

    if (!CompassCalibrationPolicy.isUnreliable(accuracy)) {
      return _status;
    }

    _unreliableSince ??= now;
    if (now.difference(_unreliableSince!) >=
        CompassCalibrationPolicy.unreliableHold) {
      _status = CompassAccuracyStatus.needsCalibration;
    }
    return _status;
  }
}

/// Estimates figure-8 / rotation coverage from compass headings.
class CompassCalibrationSampler {
  static const int _binCount = 8;
  static const double _completionThreshold = 0.8;

  final List<bool> _headingBins = List<bool>.filled(_binCount, false);
  double? _lastHeading;
  double _motionDegrees = 0;

  double get progress {
    final coverage =
        _headingBins.where((occupied) => occupied).length / _binCount;
    final motion = (_motionDegrees / 360).clamp(0.0, 1.0);
    return (coverage * 0.55 + motion * 0.45).clamp(0.0, 1.0);
  }

  bool get isComplete => progress >= _completionThreshold;

  void addHeading(double heading) {
    if (!heading.isFinite) return;
    final normalized = HeadingUtils.normalize(heading);
    _headingBins[(normalized ~/ (360 / _binCount)) % _binCount] = true;
    if (_lastHeading != null) {
      _motionDegrees += HeadingUtils.shortestDelta(
        _lastHeading!,
        normalized,
      ).abs();
    }
    _lastHeading = normalized;
  }

  void reset() {
    _headingBins.fillRange(0, _headingBins.length, false);
    _lastHeading = null;
    _motionDegrees = 0;
  }
}
