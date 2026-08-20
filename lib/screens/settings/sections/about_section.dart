part of '../../map_screen.dart';

extension _AboutSettingsSection on _MapScreenState {
  List<Widget> _buildAboutSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      SettingsSectionHeader(
        title: l10n.settingsSectionAbout,
        icon: Icons.info_outline,
      ),
      ListTile(
        title: Text(l10n.settingsCheckForUpdates),
        subtitle: Text(l10n.settingsAboutCurrentVersion(appVersion)),
        leading: const Icon(Icons.system_update),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          _checkForUpdates();
        },
      ),
      ListTile(
        title: Text(l10n.settingsViewOnGitHub),
        subtitle: Text(l10n.settingsViewOnGitHubSubtitle),
        leading: const Icon(Icons.code),
        trailing: const Icon(Icons.open_in_new),
        onTap: () {
          _openGitHub();
        },
      ),
    ];
  }
}
