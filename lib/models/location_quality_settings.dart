class LocationQualitySettings {
  static const double defaultMaxHorizontalAccuracyMeters = 250;
  static const double defaultAirborneAltitudeMeters = 500;
  static const double defaultAirborneSpeedMetersPerSecond = 45;
  static const double defaultMaxWardriveSpeedMetersPerSecond = 83.33;

  const LocationQualitySettings({
    this.maxHorizontalAccuracyMeters = defaultMaxHorizontalAccuracyMeters,
    this.airborneAltitudeMeters = defaultAirborneAltitudeMeters,
    this.airborneSpeedMetersPerSecond = defaultAirborneSpeedMetersPerSecond,
    this.maxWardriveSpeedMetersPerSecond =
        defaultMaxWardriveSpeedMetersPerSecond,
  });

  final double maxHorizontalAccuracyMeters;
  final double airborneAltitudeMeters;
  final double airborneSpeedMetersPerSecond;
  final double maxWardriveSpeedMetersPerSecond;

  LocationQualitySettings copyWith({
    double? maxHorizontalAccuracyMeters,
    double? airborneAltitudeMeters,
    double? airborneSpeedMetersPerSecond,
    double? maxWardriveSpeedMetersPerSecond,
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
    );
  }
}
