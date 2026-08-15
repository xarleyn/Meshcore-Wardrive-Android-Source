part of '../../map_screen.dart';

extension _BackupSettingsSection on _MapScreenState {
  List<Widget> _buildBackupSettings(BuildContext context) => [
    const SettingsSectionHeader(
      title: 'Settings backup',
      icon: Icons.settings_backup_restore,
    ),
    ListTile(
      title: const Text('Export Settings'),
      subtitle: const Text('Save all app settings to file'),
      leading: const Icon(Icons.upload_file),
      onTap: () {
        Navigator.pop(context);
        _exportSettings();
      },
    ),
    ListTile(
      title: const Text('Import Settings'),
      subtitle: const Text('Load settings from file'),
      leading: const Icon(Icons.download),
      onTap: () {
        Navigator.pop(context);
        _importSettings();
      },
    ),
  ];
}
