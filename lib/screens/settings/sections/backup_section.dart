import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../widgets/settings_section_header.dart';

List<Widget> buildBackupSettings(
  BuildContext context, {
  required VoidCallback onExportSettings,
  required VoidCallback onImportSettings,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    SettingsSectionHeader(
      title: l10n.settingsSectionBackup,
      icon: Icons.settings_backup_restore,
    ),
    ListTile(
      title: Text(l10n.settingsExportSettings),
      subtitle: Text(l10n.settingsExportSettingsSubtitle),
      leading: const Icon(Icons.upload_file),
      onTap: onExportSettings,
    ),
    ListTile(
      title: Text(l10n.settingsImportSettings),
      subtitle: Text(l10n.settingsImportSettingsSubtitle),
      leading: const Icon(Icons.download),
      onTap: onImportSettings,
    ),
  ];
}
