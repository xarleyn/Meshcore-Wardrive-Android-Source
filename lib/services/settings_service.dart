import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_locale.dart';
import '../models/location_quality_settings.dart';
import '../utils/bluetooth_scan.dart';
import 'upload_service.dart';

enum CurrentLocationMarkerStyle { circle, arrow }

enum MapThemeMode { system, light, dark }

/// Minimal read/write/delete boundary over platform secure storage.
///
/// Isolates the device storage boundary so tests can substitute an in-memory
/// fake instead of touching the real keychain/keystore (AGENTS.md: "Isolate
/// device and network boundaries so they can be faked").
abstract class SecureCredentialsStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Default [SecureCredentialsStore] backed by [FlutterSecureStorage].
///
/// Android keeps the plugin v10 defaults (KeyStore-wrapped AES-GCM with
/// `resetOnError` and automatic cipher migration). The legacy
/// `encryptedSharedPreferences` flag is deprecated and ignored by the plugin
/// since v10, so it is intentionally left unset.
class FlutterSecureCredentialsStore implements SecureCredentialsStore {
  const FlutterSecureCredentialsStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SettingsService {
  SettingsService({SecureCredentialsStore? credentialsStore})
    : _credentials = credentialsStore ?? const FlutterSecureCredentialsStore();

  final SecureCredentialsStore _credentials;

  static const String _showSamplesKey = 'show_samples';
  static const String _showGpsSamplesKey = 'show_gps_samples';
  static const String _fixedSampleMarkerSizeEnabledKey =
      'fixed_sample_marker_size_enabled';
  static const String _sampleMarkerRadiusKey = 'sample_marker_radius';
  static const String _showCoverageKey = 'show_coverage';
  static const String _showEdgesKey = 'show_edges';
  static const String _showRepeatersKey = 'show_repeaters';
  static const String _showPrivacyZonesKey = 'show_privacy_zones';
  static const String _showGpsExclusionZonesKey = 'show_gps_exclusion_zones';
  static const String _colorModeKey = 'color_mode';
  static const String _pingIntervalKey = 'ping_interval_meters';
  static const String _coveragePrecisionKey = 'coverage_precision';
  static const String _ignoredRepeaterPrefixKey = 'ignored_repeater_prefix';
  static const String _includeOnlyRepeatersKey = 'include_only_repeaters';
  static const String _filterEdgesByWhitelistKey = 'filter_edges_by_whitelist';
  static const String _distanceUnitKey = 'distance_unit';
  static const String _colorBlindModeKey = 'color_blind_mode';
  static const String _discoveryTimeoutKey = 'discovery_timeout_seconds';
  static const String _thoroughResponseCollectionKey =
      'thorough_response_collection';
  static const String _totalDistanceDrivenKey = 'total_distance_driven_meters';
  static const String _vehicleMpgKey = 'vehicle_mpg';
  static const String _gasPriceKey = 'gas_price_per_gallon';
  static const String _fuelUnitKey = 'fuel_unit';
  static const String _showRouteTrailKey = 'show_route_trail';
  static const String _showHeatmapKey = 'show_heatmap';
  static const String _showPredictionRingsKey = 'show_prediction_rings';
  static const String _showRadioPositionKey = 'show_radio_position';
  static const String _beaconDbWifiPositioningKey = 'beacondb_wifi_positioning';
  static const String _maxHorizontalAccuracyMetersKey =
      'location_max_horizontal_accuracy_meters';
  static const String _airborneAltitudeMetersKey =
      'location_airborne_altitude_meters';
  static const String _airborneSpeedMetersPerSecondKey =
      'location_airborne_speed_meters_per_second';
  static const String _maxWardriveSpeedMetersPerSecondKey =
      'location_max_wardrive_speed_meters_per_second';
  static const String _pausePingsOnBadFixesKey =
      'location_pause_pings_on_bad_fixes';
  static const String _pingPauseBadFixCountKey =
      'location_ping_pause_bad_fix_count';
  static const String _showDuctingKey = 'show_ducting';
  static const String _goalCenterLatKey = 'goal_center_lat';
  static const String _goalCenterLonKey = 'goal_center_lon';
  static const String _goalRadiusMetersKey = 'goal_radius_meters';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _pingModeKey = 'ping_mode';
  static const String _pingTimeIntervalKey = 'ping_time_interval_seconds';
  static const String _carpeaterEnabledKey = 'carpeater_enabled';
  static const String _carpeaterRepeaterIdKey = 'carpeater_repeater_id';
  // Carpeater password: the value lives in secure storage. This key doubles
  // as the secure-storage key and as the legacy plaintext prefs key that the
  // one-time migration moves out of SharedPreferences.
  static const String _carpeaterPasswordKey = 'carpeater_password';
  static const String _carpeaterIntervalKey = 'carpeater_interval_seconds';
  static const String _deviceNameKey = 'device_name';
  static const String _companionNodeNameKey = 'companion_node_name';
  static const String _lockRotationKey = 'lock_rotation_north';
  static const String _keepScreenOnKey = 'keep_screen_on';
  static const String _currentLocationMarkerStyleKey =
      'current_location_marker_style';
  static const String _compassCalibrationQuietUntilKey =
      'compass_calibration_quiet_until_ms';
  static const String _showSuccessfulOnlyKey = 'show_successful_only';
  static const String _optimisticDisplayKey = 'optimistic_display';
  static const String _deadZoneAlertsKey = 'dead_zone_alerts_enabled';
  static const String _newRepeaterAlertsKey = 'new_repeater_alerts_enabled';
  static const String _linkLossAlertsKey = 'link_loss_alerts_enabled';
  static const String _batterySaverEnabledKey = 'battery_saver_enabled';
  static const String _mapThemeModeKey = 'map_theme_mode';
  static const String _appLocaleKey = 'app_locale';
  static const String _mapLodEnabledKey = 'map_lod_enabled';
  static const String _sampleGeohashGroupingKey = 'map_sample_geohash_grouping';
  static const String _recentBluetoothDevicesKey = 'recent_bluetooth_devices';
  static const int _maxRecentBluetoothDevices = 8;

  static const double minSampleMarkerRadius = 4;
  static const double maxSampleMarkerRadius = 16;
  static const double defaultSampleMarkerRadius = 10;

  /// Resolved [SharedPreferences], kept after the first load. The loading
  /// future itself is memoized so concurrent first callers do not each hit
  /// the plugin. Instance-scoped (not static) on purpose: a fresh
  /// [SettingsService] re-resolves whatever [SharedPreferences.getInstance]
  /// currently returns, which keeps tests that swap mock initial values
  /// between cases isolated.
  SharedPreferences? _prefsInstance;
  Future<SharedPreferences>? _prefsFuture;

  Future<SharedPreferences> get _prefs {
    final instance = _prefsInstance;
    if (instance != null) return Future<SharedPreferences>.value(instance);
    return _prefsFuture ??= SharedPreferences.getInstance().then((prefs) {
      _prefsInstance = prefs;
      return prefs;
    });
  }

  // Alert toggles
  Future<bool> getDeadZoneAlertsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_deadZoneAlertsKey) ?? true;
  }

  Future<void> setDeadZoneAlertsEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_deadZoneAlertsKey, value);
  }

  Future<bool> getNewRepeaterAlertsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_newRepeaterAlertsKey) ?? true;
  }

  Future<void> setNewRepeaterAlertsEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_newRepeaterAlertsKey, value);
  }

  Future<bool> getLinkLossAlertsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_linkLossAlertsKey) ?? true;
  }

  Future<void> setLinkLossAlertsEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_linkLossAlertsKey, value);
  }

  Future<bool> getBatterySaverEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_batterySaverEnabledKey) ?? true;
  }

  Future<void> setBatterySaverEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_batterySaverEnabledKey, value);
  }

  Future<bool> getShowSamples() async {
    final prefs = await _prefs;
    return prefs.getBool(_showSamplesKey) ?? false;
  }

  Future<void> setShowSamples(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showSamplesKey, value);
  }

  Future<bool> getShowGpsSamples() async {
    final prefs = await _prefs;
    return prefs.getBool(_showGpsSamplesKey) ?? true;
  }

  Future<void> setShowGpsSamples(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showGpsSamplesKey, value);
  }

  Future<bool> getShowPrivacyZones() async {
    final prefs = await _prefs;
    return prefs.getBool(_showPrivacyZonesKey) ?? true;
  }

  Future<void> setShowPrivacyZones(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showPrivacyZonesKey, value);
  }

  Future<bool> getShowGpsExclusionZones() async {
    final prefs = await _prefs;
    return prefs.getBool(_showGpsExclusionZonesKey) ?? false;
  }

  Future<void> setShowGpsExclusionZones(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showGpsExclusionZonesKey, value);
  }

  /// Whether sample points use [getSampleMarkerRadius] instead of their
  /// automatic size, which varies with the number of grouped measurements.
  Future<bool> getFixedSampleMarkerSizeEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_fixedSampleMarkerSizeEnabledKey) ?? false;
  }

  Future<void> setFixedSampleMarkerSizeEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_fixedSampleMarkerSizeEnabledKey, value);
  }

  Future<double> getSampleMarkerRadius() async {
    final prefs = await _prefs;
    final value = prefs.getDouble(_sampleMarkerRadiusKey);
    if (value == null ||
        !value.isFinite ||
        value < minSampleMarkerRadius ||
        value > maxSampleMarkerRadius) {
      return defaultSampleMarkerRadius;
    }
    return value;
  }

  Future<void> setSampleMarkerRadius(double value) async {
    if (!value.isFinite ||
        value < minSampleMarkerRadius ||
        value > maxSampleMarkerRadius) {
      throw ArgumentError.value(value, 'value', 'Unsupported marker radius');
    }
    final prefs = await _prefs;
    await prefs.setDouble(_sampleMarkerRadiusKey, value);
  }

  Future<bool> getShowCoverage() async {
    final prefs = await _prefs;
    return prefs.getBool(_showCoverageKey) ?? true;
  }

  Future<void> setShowCoverage(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showCoverageKey, value);
  }

  Future<bool> getShowEdges() async {
    final prefs = await _prefs;
    return prefs.getBool(_showEdgesKey) ?? true;
  }

  Future<void> setShowEdges(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showEdgesKey, value);
  }

  Future<bool> getShowRepeaters() async {
    final prefs = await _prefs;
    return prefs.getBool(_showRepeatersKey) ?? true;
  }

  Future<void> setShowRepeaters(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showRepeatersKey, value);
  }

  Future<String> getColorMode() async {
    final prefs = await _prefs;
    return prefs.getString(_colorModeKey) ?? 'quality';
  }

  Future<void> setColorMode(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_colorModeKey, value);
  }

  Future<double> getPingInterval() async {
    final prefs = await _prefs;
    return prefs.getDouble(_pingIntervalKey) ?? 805.0; // Default 0.5 miles
  }

  Future<void> setPingInterval(double value) async {
    final prefs = await _prefs;
    await prefs.setDouble(_pingIntervalKey, value);
  }

  Future<int> getCoveragePrecision() async {
    final prefs = await _prefs;
    return prefs.getInt(_coveragePrecisionKey) ?? 7; // ~150m coverage cells
  }

  Future<void> setCoveragePrecision(int value) async {
    final prefs = await _prefs;
    await prefs.setInt(_coveragePrecisionKey, value);
  }

  Future<String?> getIgnoredRepeaterPrefix() async {
    final prefs = await _prefs;
    return prefs.getString(_ignoredRepeaterPrefixKey);
  }

  Future<void> setIgnoredRepeaterPrefix(String? value) async {
    final prefs = await _prefs;
    if (value == null || value.isEmpty) {
      await prefs.remove(_ignoredRepeaterPrefixKey);
    } else {
      await prefs.setString(_ignoredRepeaterPrefixKey, value);
    }
  }

  /// Get comma-separated list of repeater prefixes to ONLY hear from (whitelist)
  /// Empty or null = hear from all repeaters
  Future<String?> getIncludeOnlyRepeaters() async {
    final prefs = await _prefs;
    return prefs.getString(_includeOnlyRepeatersKey);
  }

  Future<void> setIncludeOnlyRepeaters(String? value) async {
    final prefs = await _prefs;
    if (value == null || value.isEmpty) {
      await prefs.remove(_includeOnlyRepeatersKey);
    } else {
      await prefs.setString(_includeOnlyRepeatersKey, value);
    }
  }

  /// Whether to filter edges (purple lines) by the Include Only Repeaters whitelist
  Future<bool> getFilterEdgesByWhitelist() async {
    final prefs = await _prefs;
    return prefs.getBool(_filterEdgesByWhitelistKey) ?? false;
  }

  Future<void> setFilterEdgesByWhitelist(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_filterEdgesByWhitelistKey, value);
  }

  /// Get distance unit ('miles' or 'km')
  Future<String> getDistanceUnit() async {
    final prefs = await _prefs;
    return prefs.getString(_distanceUnitKey) ?? 'km';
  }

  Future<void> setDistanceUnit(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_distanceUnitKey, value);
  }

  /// Get color blind mode ('normal', 'deuteranopia', 'protanopia', 'tritanopia')
  Future<String> getColorBlindMode() async {
    final prefs = await _prefs;
    return prefs.getString(_colorBlindModeKey) ?? 'normal';
  }

  Future<void> setColorBlindMode(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_colorBlindModeKey, value);
  }

  /// Get discovery timeout in seconds (5-30 seconds, default 10)
  Future<int> getDiscoveryTimeout() async {
    final prefs = await _prefs;
    return prefs.getInt(_discoveryTimeoutKey) ?? 10;
  }

  Future<void> setDiscoveryTimeout(int value) async {
    final prefs = await _prefs;
    await prefs.setInt(_discoveryTimeoutKey, value);
  }

  /// Whether discovery should keep collecting responses until its timeout.
  ///
  /// Disabled by default to preserve the fast mode, which completes the
  /// collection three seconds after the first response.
  Future<bool> getThoroughResponseCollection() async {
    final prefs = await _prefs;
    return prefs.getBool(_thoroughResponseCollectionKey) ?? false;
  }

  Future<void> setThoroughResponseCollection(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_thoroughResponseCollectionKey, value);
  }

  /// Get total distance driven across all sessions (in meters)
  Future<double> getTotalDistanceDriven() async {
    final prefs = await _prefs;
    return prefs.getDouble(_totalDistanceDrivenKey) ?? 0.0;
  }

  /// Add distance from a session to the persistent total
  Future<void> addToTotalDistanceDriven(double meters) async {
    final prefs = await _prefs;
    final current = prefs.getDouble(_totalDistanceDrivenKey) ?? 0.0;
    await prefs.setDouble(_totalDistanceDrivenKey, current + meters);
  }

  /// Reset total distance driven
  Future<void> resetTotalDistanceDriven() async {
    final prefs = await _prefs;
    await prefs.setDouble(_totalDistanceDrivenKey, 0.0);
  }

  /// Get vehicle MPG (miles per gallon), null if not set
  Future<double?> getVehicleMpg() async {
    final prefs = await _prefs;
    return prefs.getDouble(_vehicleMpgKey);
  }

  /// Set vehicle MPG
  Future<void> setVehicleMpg(double? value) async {
    final prefs = await _prefs;
    if (value == null) {
      await prefs.remove(_vehicleMpgKey);
    } else {
      await prefs.setDouble(_vehicleMpgKey, value);
    }
  }

  /// Get gas price per gallon (default 3.50)
  Future<double> getGasPrice() async {
    final prefs = await _prefs;
    return prefs.getDouble(_gasPriceKey) ?? 3.50;
  }

  /// Set gas price per gallon
  Future<void> setGasPrice(double value) async {
    final prefs = await _prefs;
    await prefs.setDouble(_gasPriceKey, value);
  }

  /// Get fuel unit ('imperial' or 'metric')
  Future<String> getFuelUnit() async {
    final prefs = await _prefs;
    return prefs.getString(_fuelUnitKey) ?? 'metric';
  }

  /// Set fuel unit ('imperial' or 'metric')
  Future<void> setFuelUnit(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_fuelUnitKey, value);
  }

  /// Get show route trail setting
  Future<bool> getShowRouteTrail() async {
    final prefs = await _prefs;
    return prefs.getBool(_showRouteTrailKey) ?? false;
  }

  /// Set show route trail setting
  Future<void> setShowRouteTrail(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showRouteTrailKey, value);
  }

  /// Get show heatmap setting
  Future<bool> getShowHeatmap() async {
    final prefs = await _prefs;
    return prefs.getBool(_showHeatmapKey) ?? false;
  }

  /// Set show heatmap setting
  Future<void> setShowHeatmap(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showHeatmapKey, value);
  }

  /// Get show prediction rings setting
  Future<bool> getShowPredictionRings() async {
    final prefs = await _prefs;
    return prefs.getBool(_showPredictionRingsKey) ?? false;
  }

  /// Set show prediction rings setting
  Future<void> setShowPredictionRings(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showPredictionRingsKey, value);
  }

  /// Whether the already-computed radio position estimate is drawn on the map.
  Future<bool> getShowRadioPosition() async {
    final prefs = await _prefs;
    return prefs.getBool(_showRadioPositionKey) ?? true;
  }

  Future<void> setShowRadioPosition(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showRadioPositionKey, value);
  }

  /// Whether nearby Wi-Fi BSSIDs may be sent to beaconDB for positioning.
  /// Disabled by default because this sends radio observations to a third
  /// party and requires network access.
  Future<bool> getBeaconDbWifiPositioning() async {
    final prefs = await _prefs;
    return prefs.getBool(_beaconDbWifiPositioningKey) ?? false;
  }

  Future<void> setBeaconDbWifiPositioning(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_beaconDbWifiPositioningKey, value);
  }

  Future<LocationQualitySettings> getLocationQualitySettings() async {
    final prefs = await _prefs;
    return LocationQualitySettings(
      maxHorizontalAccuracyMeters: _positiveOrDefault(
        prefs.getDouble(_maxHorizontalAccuracyMetersKey),
        LocationQualitySettings.defaultMaxHorizontalAccuracyMeters,
      ),
      airborneAltitudeMeters: _positiveOrDefault(
        prefs.getDouble(_airborneAltitudeMetersKey),
        LocationQualitySettings.defaultAirborneAltitudeMeters,
      ),
      airborneSpeedMetersPerSecond: _positiveOrDefault(
        prefs.getDouble(_airborneSpeedMetersPerSecondKey),
        LocationQualitySettings.defaultAirborneSpeedMetersPerSecond,
      ),
      maxWardriveSpeedMetersPerSecond: _positiveOrDefault(
        prefs.getDouble(_maxWardriveSpeedMetersPerSecondKey),
        LocationQualitySettings.defaultMaxWardriveSpeedMetersPerSecond,
      ),
      pausePingsOnBadFixes:
          prefs.getBool(_pausePingsOnBadFixesKey) ??
          LocationQualitySettings.defaultPausePingsOnBadFixes,
      pingPauseBadFixCount: _intInRangeOrDefault(
        prefs.getInt(_pingPauseBadFixCountKey),
        LocationQualitySettings.defaultPingPauseBadFixCount,
        LocationQualitySettings.minPingPauseBadFixCount,
        LocationQualitySettings.maxPingPauseBadFixCount,
      ),
    );
  }

  Future<void> setLocationQualitySettings(
    LocationQualitySettings settings,
  ) async {
    final values = [
      settings.maxHorizontalAccuracyMeters,
      settings.airborneAltitudeMeters,
      settings.airborneSpeedMetersPerSecond,
      settings.maxWardriveSpeedMetersPerSecond,
    ];
    if (values.any((value) => !value.isFinite || value <= 0)) {
      throw ArgumentError.value(
        settings,
        'settings',
        'values must be positive',
      );
    }
    final badFixCount = settings.pingPauseBadFixCount;
    if (badFixCount < LocationQualitySettings.minPingPauseBadFixCount ||
        badFixCount > LocationQualitySettings.maxPingPauseBadFixCount) {
      throw ArgumentError.value(
        settings,
        'settings',
        'pingPauseBadFixCount must be between '
            '${LocationQualitySettings.minPingPauseBadFixCount} and '
            '${LocationQualitySettings.maxPingPauseBadFixCount}',
      );
    }

    final prefs = await _prefs;
    await prefs.setDouble(
      _maxHorizontalAccuracyMetersKey,
      settings.maxHorizontalAccuracyMeters,
    );
    await prefs.setDouble(
      _airborneAltitudeMetersKey,
      settings.airborneAltitudeMeters,
    );
    await prefs.setDouble(
      _airborneSpeedMetersPerSecondKey,
      settings.airborneSpeedMetersPerSecond,
    );
    await prefs.setDouble(
      _maxWardriveSpeedMetersPerSecondKey,
      settings.maxWardriveSpeedMetersPerSecond,
    );
    await prefs.setBool(
      _pausePingsOnBadFixesKey,
      settings.pausePingsOnBadFixes,
    );
    await prefs.setInt(_pingPauseBadFixCountKey, settings.pingPauseBadFixCount);
  }

  double _positiveOrDefault(double? value, double defaultValue) {
    if (value == null || !value.isFinite || value <= 0) return defaultValue;
    return value;
  }

  int _intInRangeOrDefault(int? value, int defaultValue, int min, int max) {
    if (value == null || value < min || value > max) return defaultValue;
    return value;
  }

  /// Get show ducting monitor setting
  Future<bool> getShowDucting() async {
    final prefs = await _prefs;
    return prefs.getBool(_showDuctingKey) ?? false;
  }

  /// Set show ducting monitor setting
  Future<void> setShowDucting(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showDuctingKey, value);
  }

  // Coverage goal settings

  Future<double?> getGoalCenterLat() async {
    final prefs = await _prefs;
    return prefs.getDouble(_goalCenterLatKey);
  }

  Future<double?> getGoalCenterLon() async {
    final prefs = await _prefs;
    return prefs.getDouble(_goalCenterLonKey);
  }

  Future<double> getGoalRadiusMeters() async {
    final prefs = await _prefs;
    return prefs.getDouble(_goalRadiusMetersKey) ?? 8047.0; // Default 5 miles
  }

  Future<void> setGoal(double lat, double lon, double radiusMeters) async {
    final prefs = await _prefs;
    await prefs.setDouble(_goalCenterLatKey, lat);
    await prefs.setDouble(_goalCenterLonKey, lon);
    await prefs.setDouble(_goalRadiusMetersKey, radiusMeters);
  }

  Future<void> clearGoal() async {
    final prefs = await _prefs;
    await prefs.remove(_goalCenterLatKey);
    await prefs.remove(_goalCenterLonKey);
    await prefs.remove(_goalRadiusMetersKey);
  }

  // Ping mode: 'distance', 'time', or 'both'

  Future<String> getPingMode() async {
    final prefs = await _prefs;
    return prefs.getString(_pingModeKey) ?? 'time';
  }

  Future<void> setPingMode(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_pingModeKey, value);
  }

  Future<int> getPingTimeInterval() async {
    final prefs = await _prefs;
    return prefs.getInt(_pingTimeIntervalKey) ?? 30;
  }

  Future<void> setPingTimeInterval(int value) async {
    final prefs = await _prefs;
    await prefs.setInt(_pingTimeIntervalKey, value);
  }

  // Sound feedback

  Future<bool> getSoundEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_soundEnabledKey, value);
  }

  Future<bool> getVibrationEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  Future<void> setVibrationEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_vibrationEnabledKey, value);
  }

  // Ping mode:

  Future<bool> getCarpeaterEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_carpeaterEnabledKey) ?? false;
  }

  Future<void> setCarpeaterEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_carpeaterEnabledKey, value);
  }

  Future<String?> getCarpeaterRepeaterId() async {
    final prefs = await _prefs;
    return prefs.getString(_carpeaterRepeaterIdKey);
  }

  Future<void> setCarpeaterRepeaterId(String? value) async {
    final prefs = await _prefs;
    if (value == null || value.isEmpty) {
      await prefs.remove(_carpeaterRepeaterIdKey);
    } else {
      await prefs.setString(_carpeaterRepeaterIdKey, value);
    }
  }

  /// Carpeater admin password, stored only in platform secure storage —
  /// never in plaintext prefs, never in settings export/import.
  ///
  /// Reads transparently migrate a legacy plaintext value from
  /// SharedPreferences (read-old → write-secure → remove-old), so an update
  /// over an existing installation keeps the saved password. If the secure
  /// write fails the legacy value stays in place and is still returned; the
  /// next read retries the migration, which makes it idempotent.
  Future<String?> getCarpeaterPassword() async {
    final secureValue = await _credentials.read(_carpeaterPasswordKey);
    if (secureValue != null) {
      return secureValue;
    }
    final prefs = await _prefs;
    final legacyValue = prefs.getString(_carpeaterPasswordKey);
    if (legacyValue == null || legacyValue.isEmpty) {
      return null;
    }
    try {
      await _credentials.write(_carpeaterPasswordKey, legacyValue);
      await prefs.remove(_carpeaterPasswordKey);
    } catch (_) {
      // Migration failed: keep the legacy copy so the credential is not lost.
    }
    return legacyValue;
  }

  Future<void> setCarpeaterPassword(String? value) async {
    if (value == null || value.isEmpty) {
      await _credentials.delete(_carpeaterPasswordKey);
    } else {
      await _credentials.write(_carpeaterPasswordKey, value);
    }
    // Drop any pre-migration plaintext copy once the secure value is in
    // place; a failure above leaves it untouched so nothing is lost.
    final prefs = await _prefs;
    await prefs.remove(_carpeaterPasswordKey);
  }

  Future<int> getCarpeaterInterval() async {
    final prefs = await _prefs;
    return prefs.getInt(_carpeaterIntervalKey) ?? 30;
  }

  Future<void> setCarpeaterInterval(int value) async {
    final prefs = await _prefs;
    await prefs.setInt(_carpeaterIntervalKey, value);
  }

  /// Get device/operator name for multi-device wardrive
  Future<String?> getDeviceName() async {
    final prefs = await _prefs;
    return prefs.getString(_deviceNameKey);
  }

  /// Set device/operator name
  Future<void> setDeviceName(String? value) async {
    final prefs = await _prefs;
    if (value == null || value.isEmpty) {
      await prefs.remove(_deviceNameKey);
    } else {
      await prefs.setString(_deviceNameKey, value);
    }
  }

  /// MeshCore advert name reported by the connected companion radio, or null
  /// while no companion connection is active. Runtime state, not a preference:
  /// it is refreshed by [LoRaCompanionService] on every self-info frame and is
  /// intentionally excluded from settings export/import.
  Future<String?> getCompanionNodeName() async {
    final prefs = await _prefs;
    return prefs.getString(_companionNodeNameKey);
  }

  /// Set or clear the connected companion radio's MeshCore advert name.
  Future<void> setCompanionNodeName(String? value) async {
    final prefs = await _prefs;
    if (value == null || value.isEmpty) {
      await prefs.remove(_companionNodeNameKey);
    } else {
      await prefs.setString(_companionNodeNameKey, value);
    }
  }

  Future<List<KnownBluetoothDevice>> getRecentBluetoothDevices() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_recentBluetoothDevicesKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map)
            KnownBluetoothDevice(
              remoteId: '${item['remoteId'] ?? ''}',
              name: '${item['name'] ?? ''}',
            ),
      ].where((device) => device.remoteId.trim().isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> rememberBluetoothDevice({
    required String remoteId,
    required String name,
  }) async {
    if (remoteId.trim().isEmpty) return;
    final remembered = collectKnownBluetoothDevices(
      recent: [
        KnownBluetoothDevice(remoteId: remoteId, name: name),
        ...await getRecentBluetoothDevices(),
      ],
    );
    final prefs = await _prefs;
    await prefs.setString(
      _recentBluetoothDevicesKey,
      jsonEncode([
        for (final device in remembered.take(_maxRecentBluetoothDevices))
          {'remoteId': device.remoteId, 'name': device.name},
      ]),
    );
  }

  Future<bool> getShowSuccessfulOnly() async {
    final prefs = await _prefs;
    return prefs.getBool(_showSuccessfulOnlyKey) ?? false;
  }

  Future<void> setShowSuccessfulOnly(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_showSuccessfulOnlyKey, value);
  }

  /// Whether coverage cells with at least one successful ping render as good,
  /// ignoring failed pings unless the success went stale (see
  /// [AggregationService.optimisticStalenessDays]).
  Future<bool> getOptimisticDisplay() async {
    final prefs = await _prefs;
    return prefs.getBool(_optimisticDisplayKey) ?? false;
  }

  Future<void> setOptimisticDisplay(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_optimisticDisplayKey, value);
  }

  Future<bool> getMapLodEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_mapLodEnabledKey) ?? true;
  }

  Future<void> setMapLodEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_mapLodEnabledKey, value);
  }

  /// Whether every measurement inside one geohash cell collapses into a
  /// single sample marker regardless of zoom.
  Future<bool> getSampleGeohashGrouping() async {
    final prefs = await _prefs;
    return prefs.getBool(_sampleGeohashGroupingKey) ?? false;
  }

  Future<void> setSampleGeohashGrouping(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_sampleGeohashGroupingKey, value);
  }

  /// Get lock rotation north setting
  Future<bool> getLockRotationNorth() async {
    final prefs = await _prefs;
    return prefs.getBool(_lockRotationKey) ?? false;
  }

  /// Set lock rotation north setting
  Future<void> setLockRotationNorth(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_lockRotationKey, value);
  }

  /// Whether the display should stay awake while the app is open.
  Future<bool> getKeepScreenOn() async {
    final prefs = await _prefs;
    return prefs.getBool(_keepScreenOnKey) ?? false;
  }

  Future<void> setKeepScreenOn(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keepScreenOnKey, value);
  }

  Future<CurrentLocationMarkerStyle> getCurrentLocationMarkerStyle() async {
    final prefs = await _prefs;
    final storedValue = prefs.getString(_currentLocationMarkerStyleKey);
    return CurrentLocationMarkerStyle.values.firstWhere(
      (style) => style.name == storedValue,
      orElse: () => CurrentLocationMarkerStyle.circle,
    );
  }

  Future<void> setCurrentLocationMarkerStyle(
    CurrentLocationMarkerStyle value,
  ) async {
    final prefs = await _prefs;
    await prefs.setString(_currentLocationMarkerStyleKey, value.name);
  }

  /// Local quiet period for the compass calibration banner. Not exported.
  Future<DateTime?> getCompassCalibrationQuietUntil() async {
    final prefs = await _prefs;
    final millis = prefs.getInt(_compassCalibrationQuietUntilKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setCompassCalibrationQuietUntil(DateTime? value) async {
    final prefs = await _prefs;
    if (value == null) {
      await prefs.remove(_compassCalibrationQuietUntilKey);
      return;
    }
    await prefs.setInt(
      _compassCalibrationQuietUntilKey,
      value.millisecondsSinceEpoch,
    );
  }

  /// Returns the independently selected map theme.
  ///
  /// Existing installations inherit their previous app-wide theme once. This
  /// keeps the map appearance stable while decoupling future interface changes.
  Future<MapThemeMode> getMapThemeMode() async {
    final prefs = await _prefs;
    final storedValue = prefs.getString(_mapThemeModeKey);
    final legacyThemeValue = prefs.getString('theme_mode');
    final value = storedValue ?? legacyThemeValue ?? MapThemeMode.system.name;
    final mode = MapThemeMode.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => MapThemeMode.system,
    );

    if (storedValue == null) {
      await prefs.setString(_mapThemeModeKey, mode.name);
    }
    return mode;
  }

  Future<void> setMapThemeMode(MapThemeMode value) async {
    final prefs = await _prefs;
    await prefs.setString(_mapThemeModeKey, value.name);
  }

  Future<AppLocalePreference> getAppLocalePreference() async {
    final prefs = await _prefs;
    return AppLocale.parse(prefs.getString(_appLocaleKey));
  }

  Future<void> setAppLocalePreference(AppLocalePreference value) async {
    final prefs = await _prefs;
    await prefs.setString(_appLocaleKey, AppLocale.persist(value));
  }

  /// All preference keys that should be exported/imported
  static const List<String> _exportKeys = [
    _showSamplesKey,
    _showGpsSamplesKey,
    _fixedSampleMarkerSizeEnabledKey,
    _sampleMarkerRadiusKey,
    _showCoverageKey,
    _showEdgesKey,
    _showRepeatersKey,
    _showPrivacyZonesKey,
    _showGpsExclusionZonesKey,
    _colorModeKey,
    _pingIntervalKey,
    _coveragePrecisionKey,
    _ignoredRepeaterPrefixKey,
    _includeOnlyRepeatersKey,
    _filterEdgesByWhitelistKey,
    _distanceUnitKey,
    _colorBlindModeKey,
    _discoveryTimeoutKey,
    _totalDistanceDrivenKey,
    _vehicleMpgKey,
    _gasPriceKey,
    _fuelUnitKey,
    _showRouteTrailKey,
    _showHeatmapKey,
    _showPredictionRingsKey,
    _showRadioPositionKey,
    _beaconDbWifiPositioningKey,
    _maxHorizontalAccuracyMetersKey,
    _airborneAltitudeMetersKey,
    _airborneSpeedMetersPerSecondKey,
    _maxWardriveSpeedMetersPerSecondKey,
    _pausePingsOnBadFixesKey,
    _pingPauseBadFixCountKey,
    _showDuctingKey,
    _goalCenterLatKey,
    _goalCenterLonKey,
    _goalRadiusMetersKey,
    _soundEnabledKey,
    _vibrationEnabledKey,
    _pingModeKey,
    _pingTimeIntervalKey,
    _carpeaterEnabledKey,
    _carpeaterRepeaterIdKey,
    // _carpeaterPasswordKey is intentionally absent: the Carpeater password
    // lives in secure storage only and must never enter settings exports.
    // importSettings iterates this same list, so legacy export files that
    // still carry the key are skipped automatically.
    _carpeaterIntervalKey,
    _deviceNameKey,
    _lockRotationKey,
    _keepScreenOnKey,
    _batterySaverEnabledKey,
    _currentLocationMarkerStyleKey,
    _showSuccessfulOnlyKey,
    _optimisticDisplayKey,
    _mapLodEnabledKey,
    _sampleGeohashGroupingKey,
    _linkLossAlertsKey,
    _deadZoneAlertsKey,
    _newRepeaterAlertsKey,
    // Upload service keys (constants owned by UploadService)
    UploadService.apiUrlKey,
    UploadService.autoUploadKey,
    UploadService.uploadEndpointsKey,
    UploadService.selectedEndpointsKey,
    // Theme
    'theme_mode',
    _mapThemeModeKey,
    _appLocaleKey,
  ];

  /// Export all settings to a JSON-encodable map
  Future<Map<String, dynamic>> exportSettings() async {
    final prefs = await _prefs;
    final Map<String, dynamic> data = {
      '_format': 'meshcore_wardrive_settings',
      '_version': 1,
      '_exportedAt': DateTime.now().toIso8601String(),
    };

    for (final key in _exportKeys) {
      final value = prefs.get(key);
      if (value != null) {
        data[key] = value;
      }
    }

    return data;
  }

  /// Import settings from a JSON map. Returns the number of settings applied.
  Future<int> importSettings(Map<String, dynamic> data) async {
    // Validate format
    if (data['_format'] != 'meshcore_wardrive_settings') {
      throw FormatException('Not a valid MeshCore Wardrive settings file');
    }

    final prefs = await _prefs;
    int applied = 0;

    for (final key in _exportKeys) {
      if (!data.containsKey(key)) continue;
      final value = data[key];
      if (value == null) continue;

      try {
        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else {
          continue;
        }
        applied++;
      } catch (_) {
        // Skip invalid values
      }
    }

    return applied;
  }

  /// Export settings as a formatted JSON string
  Future<String> exportSettingsJson() async {
    final data = await exportSettings();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import settings from a JSON string. Returns the number of settings applied.
  Future<int> importSettingsJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return importSettings(data);
  }
}
