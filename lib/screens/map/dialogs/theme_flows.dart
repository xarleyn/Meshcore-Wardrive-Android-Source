import 'package:flutter/material.dart';

import '../../../l10n/app_locale.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../main.dart';
import '../../../services/location_service.dart';
import '../../../services/settings_service.dart';
import 'appearance_dialogs.dart';

/// Whether the map should use dark basemap tiles for [mode]; the system
/// variant resolves against [platformBrightness].
bool usesDarkMapTiles({
  required MapThemeMode mode,
  required Brightness platformBrightness,
}) {
  switch (mode) {
    case MapThemeMode.light:
      return false;
    case MapThemeMode.dark:
      return true;
    case MapThemeMode.system:
      return platformBrightness == Brightness.dark;
  }
}

/// Interface theme, language, and map theme selectors for the map screen.
///
/// The flow owns no state: interface theme and language are applied through
/// the root `MyAppState` (`MyApp.of`), the map theme mode is read from and
/// reported to the screen through callbacks, and [locationService] refreshes
/// the foreground-service notification copy after a language change.
class ThemeFlow {
  const ThemeFlow({
    required this.context,
    required this.locationService,
    required this.settingsService,
    required this.mapThemeMode,
    required this.onMapThemeModeChanged,
  });

  /// Screen context used for localization and dialogs.
  final BuildContext context;

  final LocationService locationService;
  final SettingsService settingsService;

  /// Currently selected map theme mode.
  final MapThemeMode Function() mapThemeMode;

  /// Applies a newly selected map theme mode on the screen.
  final void Function(MapThemeMode mode) onMapThemeModeChanged;

  /// Localized description of the current interface theme.
  String interfaceThemeModeText() {
    final l10n = AppLocalizations.of(context);
    final appState = MyApp.of(context);
    if (appState == null) return l10n.settingsThemeSystemDefault;

    switch (appState.themeMode) {
      case ThemeMode.light:
        return l10n.settingsThemeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeDark;
      case ThemeMode.system:
        return l10n.settingsThemeSystemDefault;
    }
  }

  /// Shows the interface theme picker and applies the selection.
  Future<void> showInterfaceThemeSelector() async {
    final appState = MyApp.of(context);
    if (appState == null) return;

    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => const InterfaceThemeDialog(),
    );

    if (selected != null) {
      await appState.setThemeMode(selected);
    }
  }

  /// Localized description of the current language preference.
  String appLocalePreferenceText() {
    final l10n = AppLocalizations.of(context);
    switch (MyApp.of(context)?.localePreference) {
      case AppLocalePreference.en:
        return l10n.languageEnglish;
      case AppLocalePreference.ru:
        return l10n.languageRussian;
      case AppLocalePreference.system:
      case null:
        return l10n.languageSystem;
    }
  }

  /// Shows the language picker, applies the selection, and refreshes the
  /// notification copy of the tracking service.
  Future<void> showLanguageSelector() async {
    final appState = MyApp.of(context);
    if (appState == null) return;

    final selected = await showDialog<AppLocalePreference>(
      context: context,
      builder: (dialogContext) => const AppLocaleDialog(),
    );

    if (selected != null) {
      await appState.setAppLocalePreference(selected);
      await locationService.refreshNotificationCopy();
    }
  }

  /// Localized description of the current map theme mode.
  String mapThemeModeText() {
    final l10n = AppLocalizations.of(context);
    switch (mapThemeMode()) {
      case MapThemeMode.light:
        return l10n.settingsThemeLight;
      case MapThemeMode.dark:
        return l10n.settingsThemeDark;
      case MapThemeMode.system:
        return l10n.settingsThemeSystemDefault;
    }
  }

  /// Shows the map theme picker and persists the selection.
  Future<void> showMapThemeSelector() async {
    final selected = await showDialog<MapThemeMode>(
      context: context,
      builder: (dialogContext) => const MapThemeDialog(),
    );

    if (selected != null) {
      onMapThemeModeChanged(selected);
      await settingsService.setMapThemeMode(selected);
    }
  }
}
