import 'package:flutter_test/flutter_test.dart';
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
}
