import 'package:flutter/material.dart';

import '../../../l10n/app_locale.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/settings_service.dart';

class InterfaceThemeDialog extends StatelessWidget {
  const InterfaceThemeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.settingsChooseInterfaceTheme),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(
            context,
            value: ThemeMode.light,
            icon: Icons.light_mode,
            label: l10n.settingsThemeLight,
          ),
          _option(
            context,
            value: ThemeMode.dark,
            icon: Icons.dark_mode,
            label: l10n.settingsThemeDark,
          ),
          _option(
            context,
            value: ThemeMode.system,
            icon: Icons.brightness_auto,
            label: l10n.settingsThemeSystemDefault,
          ),
        ],
      ),
    );
  }
}

class AppLocaleDialog extends StatelessWidget {
  const AppLocaleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.languagePickerTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(
            context,
            value: AppLocalePreference.system,
            icon: Icons.brightness_auto,
            label: l10n.languageSystem,
          ),
          _option(
            context,
            value: AppLocalePreference.en,
            icon: Icons.language,
            label: l10n.languageEnglish,
          ),
          _option(
            context,
            value: AppLocalePreference.ru,
            icon: Icons.language,
            label: l10n.languageRussian,
          ),
        ],
      ),
    );
  }
}

class MapThemeDialog extends StatelessWidget {
  const MapThemeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.settingsChooseMapTheme),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(
            context,
            value: MapThemeMode.light,
            icon: Icons.light_mode,
            label: l10n.settingsThemeLight,
          ),
          _option(
            context,
            value: MapThemeMode.dark,
            icon: Icons.dark_mode,
            label: l10n.settingsThemeDark,
          ),
          _option(
            context,
            value: MapThemeMode.system,
            icon: Icons.brightness_auto,
            label: l10n.settingsThemeSystemDefault,
          ),
        ],
      ),
    );
  }
}

Widget _option<T>(
  BuildContext context, {
  required T value,
  required IconData icon,
  required String label,
}) {
  return ListTile(
    title: Text(label),
    leading: Icon(icon),
    onTap: () => Navigator.pop(context, value),
  );
}
