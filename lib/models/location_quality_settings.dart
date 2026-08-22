class LocationQualitySettings {
  static const double defaultMaxHorizontalAccuracyMeters = 250;
  static const double defaultAirborneAltitudeMeters = 500;
  static const double defaultAirborneSpeedMetersPerSecond = 45;
  static const double defaultMaxWardriveSpeedMetersPerSecond = 83.33;
  static const bool defaultPausePingsOnBadFixes = true;
  static const int defaultPingPauseBadFixCount = 5;
  static const int minPingPauseBadFixCount = 1;
  static const int maxPingPauseBadFixCount = 100;

  const LocationQualitySettings({
    this.maxHorizontalAccuracyMeters = defaultMaxHorizontalAccuracyMeters,
    this.airborneAltitudeMeters = defaultAirborneAltitudeMeters,
    this.airborneSpeedMetersPerSecond = defaultAirborneSpeedMetersPerSecond,
    this.maxWardriveSpeedMetersPerSecond =
        defaultMaxWardriveSpeedMetersPerSecond,
    this.pausePingsOnBadFixes = defaultPausePingsOnBadFixes,
    this.pingPauseBadFixCount = defaultPingPauseBadFixCount,
  });

  final double maxHorizontalAccuracyMeters;
  final double airborneAltitudeMeters;
  final double airborneSpeedMetersPerSecond;
  final double maxWardriveSpeedMetersPerSecond;

  /// Whether automatic pinging pauses while recent position fixes keep being
  /// rejected by the quality filters.
  final bool pausePingsOnBadFixes;

  /// How many consecutive rejected fixes pause automatic pinging.
  final int pingPauseBadFixCount;

  LocationQualitySettings copyWith({
    double? maxHorizontalAccuracyMeters,
    double? airborneAltitudeMeters,
    double? airborneSpeedMetersPerSecond,
    double? maxWardriveSpeedMetersPerSecond,
    bool? pausePingsOnBadFixes,
    int? pingPauseBadFixCount,
  }) {
    return LocationQualitySettings(
      maxHorizontalAccuracyMeters:
          maxHorizontalAccuracyMeters ?? this.maxHorizontalAccuracyMeters,
      airborneAltitudeMeters:
          airborneAltitudeMeters ?? this.airborneAltitudeMeters,
      airborneSpeedMetersPerSecond:
          airborneSpeedMetersPerSecond ?? this.airborneSpeedMetersPerSecond,
      maxWardriveSpeedMetersPerSecond:
          maxWardriveSpeedMetersPerSecond ??
          this.maxWardriveSpeedMetersPerSecond,
      pausePingsOnBadFixes: pausePingsOnBadFixes ?? this.pausePingsOnBadFixes,
      pingPauseBadFixCount: pingPauseBadFixCount ?? this.pingPauseBadFixCount,
    );
  }
}
