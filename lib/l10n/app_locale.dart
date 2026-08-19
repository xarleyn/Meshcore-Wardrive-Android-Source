import 'package:flutter/material.dart';

import 'generated/app_localizations.dart';

enum AppLocalePreference { system, en, ru }

class AppLocale {
  static const List<Locale> supported = [Locale('en'), Locale('ru')];

  static AppLocalePreference parse(String? raw) {
    return switch (raw) {
      'en' => AppLocalePreference.en,
      'ru' => AppLocalePreference.ru,
      'system' || null => AppLocalePreference.system,
      _ => AppLocalePreference.system,
    };
  }

  static String persist(AppLocalePreference preference) => preference.name;

  static Locale resolve(AppLocalePreference preference, Locale system) {
    return switch (preference) {
      AppLocalePreference.en => const Locale('en'),
      AppLocalePreference.ru => const Locale('ru'),
      AppLocalePreference.system =>
        supported.any((locale) => locale.languageCode == system.languageCode)
            ? Locale(system.languageCode)
            : const Locale('en'),
    };
  }

  static AppLocalizations lookup(
    AppLocalePreference preference,
    Locale system,
  ) {
    return lookupAppLocalizations(resolve(preference, system));
  }
}
