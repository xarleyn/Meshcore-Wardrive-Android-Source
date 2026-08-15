part of '../../map_screen.dart';

extension _AboutSettingsSection on _MapScreenState {
  List<Widget> _buildAboutSettings(BuildContext context) => [
    const SettingsSectionHeader(title: 'About', icon: Icons.info_outline),
    ListTile(
      title: const Text('Check for Updates'),
      subtitle: const Text('Current version: v$appVersion'),
      leading: const Icon(Icons.system_update),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        _checkForUpdates();
      },
    ),
    ListTile(
      title: const Text('View on GitHub'),
      subtitle: const Text('Source code and releases'),
      leading: const Icon(Icons.code),
      trailing: const Icon(Icons.open_in_new),
      onTap: () {
        Navigator.pop(context);
        _openGitHub();
      },
    ),
  ];
}
