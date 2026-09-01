import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/map/map_settings_controller.dart';
import 'package:meshcore_wardrive/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads a typed snapshot and applies the same runtime settings',
    () async {
      SharedPreferences.setMockInitialValues({
        'show_samples': true,
        'show_privacy_zones': false,
        'show_gps_exclusion_zones': true,
        'fixed_sample_marker_size_enabled': true,
        'sample_marker_radius': 14.0,
        'ping_interval_meters': 1234.0,
        'ignored_repeater_prefix': 'abcd',
        'distance_unit': 'miles',
        'location_max_horizontal_accuracy_meters': 42.0,
        'map_theme_mode': 'dark',
        'ping_mode': 'distance',
        'keep_screen_on': true,
        'current_location_marker_style': 'arrow',
        'carpeater_enabled': true,
        'carpeater_repeater_id': 'beef',
        'carpeater_interval_seconds': 45,
        'link_loss_alerts_enabled': false,
        'optimistic_display': true,
      });
      final runtime = _FakeMapSettingsRuntime();
      final controller = MapSettingsController(
        settingsService: SettingsService(
          credentialsStore: _FakeCredentialsStore(),
        ),
        runtime: runtime,
      );

      final snapshot = await controller.loadAndApply();

      expect(snapshot.showSamples, isTrue);
      expect(snapshot.showPrivacyZones, isFalse);
      expect(snapshot.showGpsExclusionZones, isTrue);
      expect(snapshot.fixedSampleMarkerSizeEnabled, isTrue);
      expect(snapshot.sampleMarkerRadius, 14);
      expect(snapshot.pingIntervalMeters, 1234);
      expect(snapshot.ignoredRepeaterPrefix, 'abcd');
      expect(snapshot.distanceUnit, 'miles');
      expect(snapshot.locationQualitySettings.maxHorizontalAccuracyMeters, 42);
      expect(snapshot.mapThemeMode, MapThemeMode.dark);
      expect(snapshot.pingMode, 'distance');
      expect(snapshot.keepScreenOn, isTrue);
      expect(
        snapshot.currentLocationMarkerStyle,
        CurrentLocationMarkerStyle.arrow,
      );
      expect(snapshot.carpeaterEnabled, isTrue);
      expect(snapshot.carpeaterRepeaterId, 'beef');
      expect(snapshot.carpeaterInterval, 45);
      expect(snapshot.linkLossAlertsEnabled, isFalse);
      expect(snapshot.optimisticDisplay, isTrue);
      expect(runtime.applied, same(snapshot));
    },
  );

  test('uses SettingsService defaults for an empty preference store', () async {
    SharedPreferences.setMockInitialValues({});
    final runtime = _FakeMapSettingsRuntime();
    final controller = MapSettingsController(
      settingsService: SettingsService(
        credentialsStore: _FakeCredentialsStore(),
      ),
      runtime: runtime,
    );

    final snapshot = await controller.loadAndApply();

    expect(snapshot.showSamples, isFalse);
    expect(snapshot.fixedSampleMarkerSizeEnabled, isFalse);
    expect(
      snapshot.sampleMarkerRadius,
      SettingsService.defaultSampleMarkerRadius,
    );
    expect(snapshot.showCoverage, isTrue);
    expect(snapshot.showPrivacyZones, isTrue);
    expect(snapshot.showGpsExclusionZones, isFalse);
    expect(snapshot.mapLodEnabled, isTrue);
    expect(snapshot.optimisticDisplay, isFalse);
    expect(snapshot.distanceUnit, 'km');
    expect(snapshot.mapThemeMode, MapThemeMode.system);
    expect(
      snapshot.currentLocationMarkerStyle,
      CurrentLocationMarkerStyle.circle,
    );
    expect(snapshot.linkLossAlertsEnabled, isTrue);
    expect(runtime.applied, same(snapshot));
  });
}

class _FakeMapSettingsRuntime implements MapSettingsRuntime {
  MapSettingsSnapshot? applied;

  @override
  Future<void> apply(MapSettingsSnapshot settings) async {
    applied = settings;
  }
}

/// In-memory credentials store so the controller tests never touch the real
/// secure-storage plugin channel.
class _FakeCredentialsStore implements SecureCredentialsStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
