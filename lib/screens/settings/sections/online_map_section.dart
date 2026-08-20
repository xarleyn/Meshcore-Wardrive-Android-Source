part of '../../map_screen.dart';

extension _OnlineMapSettingsSection on _MapScreenState {
  List<Widget> _buildOnlineMapSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      SettingsSectionHeader(
        title: l10n.settingsSectionOnlineMap,
        icon: Icons.cloud_outlined,
      ),
      ListTile(
        title: Text(l10n.settingsUploadData),
        subtitle: Text(l10n.settingsUploadDataSubtitle),
        leading: const Icon(Icons.cloud_upload),
        onTap: () {
          _uploadSamples();
        },
      ),
      ListTile(
        title: Text(l10n.settingsManageUploadSites),
        subtitle: Text(l10n.settingsManageUploadSitesSubtitle),
        leading: const Icon(Icons.dns),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          _manageUploadSites();
        },
      ),
    ];
  }
}
