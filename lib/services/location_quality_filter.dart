import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

/// Rejects location fixes that would create misleading wardrive samples.
///
/// The altitude check is deliberately combined with speed. A blanket altitude
/// limit would discard legitimate drives on mountain roads.
class LocationQualityFilter {
  static const double maxHorizontalAccuracyMeters = 250;
  static const double airborneAltitudeMeters = 500;
  static const double airborneSpeedMetersPerSecond = 45;
  static const double maxWardriveSpeedMetersPerSecond = 83.33;

  Position? _lastAcceptedPosition;

  /// Returns `null` for an acceptable fix, otherwise a diagnostic reason.
  String? rejectionReason(Position position) {
    if (position.isMocked) {
      return 'Android marked the location as mocked';
    }

    if (!position.latitude.isFinite ||
        !position.longitude.isFinite ||
        position.latitude < -90 ||
        position.latitude > 90 ||
        position.longitude < -180 ||
        position.longitude > 180) {
      return 'invalid coordinates';
    }

    if (position.accuracy.isFinite &&
        position.accuracy > maxHorizontalAccuracyMeters) {
      return 'horizontal accuracy ${position.accuracy.toStringAsFixed(1)}m '
          'is worse than ${maxHorizontalAccuracyMeters.toStringAsFixed(0)}m';
    }

    final reportedSpeed = position.speed.isFinite && position.speed > 0
        ? position.speed
        : 0.0;
    final derivedSpeed = _derivedSpeed(position);
    final effectiveSpeed = math.max(reportedSpeed, derivedSpeed);

    if (position.altitude.isFinite &&
        position.altitude >= airborneAltitudeMeters &&
        effectiveSpeed >= airborneSpeedMetersPerSecond) {
      return 'probable flight: altitude '
          '${position.altitude.toStringAsFixed(0)}m, speed '
          '${(effectiveSpeed * 3.6).toStringAsFixed(0)}km/h';
    }

    if (effectiveSpeed >= maxWardriveSpeedMetersPerSecond) {
      return 'speed ${(effectiveSpeed * 3.6).toStringAsFixed(0)}km/h '
          'is too high for wardriving';
    }

    return null;
  }

  /// Records a fix as the new comparison point after it has been accepted.
  void accept(Position position) {
    _lastAcceptedPosition = position;
  }

  void reset() {
    _lastAcceptedPosition = null;
  }

  double _derivedSpeed(Position position) {
    final previous = _lastAcceptedPosition;
    if (previous == null) return 0;

    final elapsedSeconds =
        position.timestamp.difference(previous.timestamp).inMilliseconds /
        Duration.millisecondsPerSecond;
    if (elapsedSeconds <= 0) return 0;

    return _distanceMeters(
          previous.latitude,
          previous.longitude,
          position.latitude,
          position.longitude,
        ) /
        elapsedSeconds;
  }

  double _distanceMeters(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _toRadians(latitude2 - latitude1);
    final longitudeDelta = _toRadians(longitude2 - longitude1);
    final latitude1Radians = _toRadians(latitude1);
    final latitude2Radians = _toRadians(latitude2);

    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(latitude1Radians) *
            math.cos(latitude2Radians) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    final centralAngle =
        2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return earthRadiusMeters * centralAngle;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}
