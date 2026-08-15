part of '../../map_screen.dart';

extension _OnlineMapSettingsSection on _MapScreenState {
  List<Widget> _buildOnlineMapSettings(BuildContext context) => [
    const SettingsSectionHeader(
      title: 'Online map',
      icon: Icons.cloud_outlined,
    ),
    ListTile(
      title: const Text('Upload Data'),
      subtitle: const Text('Upload samples to web map'),
      leading: const Icon(Icons.cloud_upload),
      onTap: () {
        Navigator.pop(context);
        _uploadSamples();
      },
    ),
    ListTile(
      title: const Text('Manage Upload Sites'),
      subtitle: const Text('Add/edit upload endpoints'),
      leading: const Icon(Icons.dns),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        _manageUploadSites();
      },
    ),
  ];
}
