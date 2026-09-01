import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/l10n/app_locale.dart';
import 'package:meshcore_wardrive/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLocale.resolve', () {
    test('forced ru ignores device language', () {
      expect(
        AppLocale.resolve(AppLocalePreference.ru, const Locale('en', 'US')),
        const Locale('ru'),
      );
    });

    test('system uses device when supported', () {
      expect(
        AppLocale.resolve(AppLocalePreference.system, const Locale('ru', 'RU')),
        const Locale('ru'),
      );
    });

    test('system falls back to English for unsupported languages', () {
      expect(
        AppLocale.resolve(AppLocalePreference.system, const Locale('de')),
        const Locale('en'),
      );
    });
  });

  group('SettingsService app locale', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to system', () async {
      expect(
        await SettingsService().getAppLocalePreference(),
        AppLocalePreference.system,
      );
    });

    test('persists ru', () async {
      final settings = SettingsService();
      await settings.setAppLocalePreference(AppLocalePreference.ru);
      expect(await settings.getAppLocalePreference(), AppLocalePreference.ru);
    });

    test('unknown stored value falls back to system', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'zh'});
      expect(
        await SettingsService().getAppLocalePreference(),
        AppLocalePreference.system,
      );
    });

    test('export includes app_locale when set', () async {
      await SettingsService().setAppLocalePreference(AppLocalePreference.en);
      final exported = await SettingsService().exportSettings();
      expect(exported['app_locale'], 'en');
    });
  });
}
