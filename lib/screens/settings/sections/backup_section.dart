part of '../../map_screen.dart';

extension _BackupSettingsSection on _MapScreenState {
  List<Widget> _buildBackupSettings(BuildContext context) {
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
        onTap: () {
          _exportSettings();
        },
      ),
      ListTile(
        title: Text(l10n.settingsImportSettings),
        subtitle: Text(l10n.settingsImportSettingsSubtitle),
        leading: const Icon(Icons.download),
        onTap: () {
          _importSettings();
        },
      ),
    ];
  }
}
