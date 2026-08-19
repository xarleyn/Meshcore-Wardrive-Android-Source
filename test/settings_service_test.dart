import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/models/location_quality_settings.dart';
import 'package:meshcore_wardrive/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('current location marker setting', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to the circle marker', () async {
      final settings = SettingsService();

      expect(
        await settings.getCurrentLocationMarkerStyle(),
        CurrentLocationMarkerStyle.circle,
      );
    });

    test('persists the direction arrow', () async {
      final settings = SettingsService();

      await settings.setCurrentLocationMarkerStyle(
        CurrentLocationMarkerStyle.arrow,
      );

      expect(
        await settings.getCurrentLocationMarkerStyle(),
        CurrentLocationMarkerStyle.arrow,
      );
    });

    test('falls back to the circle for an unknown stored value', () async {
      SharedPreferences.setMockInitialValues({
        'current_location_marker_style': 'unknown',
      });

      expect(
        await SettingsService().getCurrentLocationMarkerStyle(),
        CurrentLocationMarkerStyle.circle,
      );
    });
  });

  group('compass calibration quiet period', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to unset', () async {
      expect(await SettingsService().getCompassCalibrationQuietUntil(), isNull);
    });

    test('persists and clears the quiet timestamp', () async {
      final settings = SettingsService();
      final until = DateTime.utc(2026, 8, 20, 12);

      await settings.setCompassCalibrationQuietUntil(until);
      expect(
        (await settings.getCompassCalibrationQuietUntil())
            ?.millisecondsSinceEpoch,
        until.millisecondsSinceEpoch,
      );

      await settings.setCompassCalibrationQuietUntil(null);
      expect(await settings.getCompassCalibrationQuietUntil(), isNull);
    });
  });

  group('keep screen on setting', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to disabled', () async {
      expect(await SettingsService().getKeepScreenOn(), isFalse);
    });

    test('persists the selected value', () async {
      final settings = SettingsService();

      await settings.setKeepScreenOn(true);

      expect(await settings.getKeepScreenOn(), isTrue);
    });
  });

  group('map theme setting', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to the system theme', () async {
      expect(await SettingsService().getMapThemeMode(), MapThemeMode.system);
    });

    test('persists the selected map theme independently', () async {
      final settings = SettingsService();

      await settings.setMapThemeMode(MapThemeMode.dark);

      expect(await settings.getMapThemeMode(), MapThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), isNull);
    });

    test('inherits and stores the legacy interface theme once', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final settings = SettingsService();

      expect(await settings.getMapThemeMode(), MapThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', 'light');
      expect(await settings.getMapThemeMode(), MapThemeMode.dark);
    });

    test('falls back to system for an unknown stored value', () async {
      SharedPreferences.setMockInitialValues({'map_theme_mode': 'sepia'});

      expect(await SettingsService().getMapThemeMode(), MapThemeMode.system);
    });

    test('includes the map theme in settings backup', () async {
      final settings = SettingsService();
      await settings.setMapThemeMode(MapThemeMode.light);

      final exported = await settings.exportSettings();

      expect(exported['map_theme_mode'], 'light');
    });
  });

  group('map LOD setting', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to enabled', () async {
      expect(await SettingsService().getMapLodEnabled(), isTrue);
    });

    test('persists the selected value', () async {
      final settings = SettingsService();

      await settings.setMapLodEnabled(false);

      expect(await settings.getMapLodEnabled(), isFalse);
    });

    test('includes map LOD in settings backup', () async {
      final settings = SettingsService();
      await settings.setMapLodEnabled(false);

      final exported = await settings.exportSettings();

      expect(exported['map_lod_enabled'], isFalse);
    });
  });

  group('radio position visibility setting', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to visible', () async {
      expect(await SettingsService().getShowRadioPosition(), isTrue);
    });

    test('persists hidden state', () async {
      final settings = SettingsService();

      await settings.setShowRadioPosition(false);

      expect(await settings.getShowRadioPosition(), isFalse);
    });
  });

  group('beaconDB Wi-Fi positioning setting', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to disabled', () async {
      expect(await SettingsService().getBeaconDbWifiPositioning(), isFalse);
    });

    test('persists the selected value', () async {
      final settings = SettingsService();

      await settings.setBeaconDbWifiPositioning(true);

      expect(await settings.getBeaconDbWifiPositioning(), isTrue);
    });
  });

  group('wardrive defaults', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('uses metric, time-based defaults from meshcoretel', () async {
      final settings = SettingsService();

      expect(await settings.getCoveragePrecision(), 7);
      expect(await settings.getDistanceUnit(), 'km');
      expect(await settings.getFuelUnit(), 'metric');
      expect(await settings.getDiscoveryTimeout(), 10);
      expect(await settings.getThoroughResponseCollection(), isFalse);
      expect(await settings.getPingMode(), 'time');
      expect(await settings.getPingTimeInterval(), 30);
    });

    test('persists thorough response collection', () async {
      final settings = SettingsService();

      await settings.setThoroughResponseCollection(true);

      expect(await settings.getThoroughResponseCollection(), isTrue);
    });
  });

  group('location quality settings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('uses the existing filter defaults', () async {
      final settings = await SettingsService().getLocationQualitySettings();

      expect(settings.maxHorizontalAccuracyMeters, 250);
      expect(settings.airborneAltitudeMeters, 500);
      expect(settings.airborneSpeedMetersPerSecond, 45);
      expect(settings.maxWardriveSpeedMetersPerSecond, 83.33);
    });

    test('persists all thresholds together', () async {
      final service = SettingsService();
      const expected = LocationQualitySettings(
        maxHorizontalAccuracyMeters: 80,
        airborneAltitudeMeters: 1200,
        airborneSpeedMetersPerSecond: 55,
        maxWardriveSpeedMetersPerSecond: 90,
      );

      await service.setLocationQualitySettings(expected);
      final actual = await service.getLocationQualitySettings();

      expect(actual.maxHorizontalAccuracyMeters, 80);
      expect(actual.airborneAltitudeMeters, 1200);
      expect(actual.airborneSpeedMetersPerSecond, 55);
      expect(actual.maxWardriveSpeedMetersPerSecond, 90);
    });

    test('replaces invalid stored values with defaults', () async {
      SharedPreferences.setMockInitialValues({
        'location_max_horizontal_accuracy_meters': -1.0,
        'location_airborne_altitude_meters': double.infinity,
      });

      final settings = await SettingsService().getLocationQualitySettings();

      expect(settings.maxHorizontalAccuracyMeters, 250);
      expect(settings.airborneAltitudeMeters, 500);
    });

    test(
      'includes all thresholds in settings backup import and export',
      () async {
        final service = SettingsService();
        const expected = LocationQualitySettings(
          maxHorizontalAccuracyMeters: 75,
          airborneAltitudeMeters: 900,
          airborneSpeedMetersPerSecond: 50,
          maxWardriveSpeedMetersPerSecond: 95,
        );
        await service.setLocationQualitySettings(expected);

        final exported = await service.exportSettings();
        expect(exported['location_max_horizontal_accuracy_meters'], 75);
        expect(exported['location_airborne_altitude_meters'], 900);
        expect(exported['location_airborne_speed_meters_per_second'], 50);
        expect(exported['location_max_wardrive_speed_meters_per_second'], 95);

        SharedPreferences.setMockInitialValues({});
        expect(await service.importSettings(exported), greaterThanOrEqualTo(4));
        final imported = await service.getLocationQualitySettings();
        expect(imported.maxHorizontalAccuracyMeters, 75);
        expect(imported.airborneAltitudeMeters, 900);
        expect(imported.airborneSpeedMetersPerSecond, 50);
        expect(imported.maxWardriveSpeedMetersPerSecond, 95);
      },
    );
  });
}
