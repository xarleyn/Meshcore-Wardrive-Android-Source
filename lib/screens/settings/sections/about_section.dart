import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../widgets/settings_section_header.dart';

List<Widget> buildAboutSettings(
  BuildContext context, {
  required String version,
  required VoidCallback onCheckForUpdates,
  required VoidCallback onOpenGitHub,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    SettingsSectionHeader(
      title: l10n.settingsSectionAbout,
      icon: Icons.info_outline,
    ),
    ListTile(
      title: Text(l10n.settingsCheckForUpdates),
      subtitle: Text(l10n.settingsAboutCurrentVersion(version)),
      leading: const Icon(Icons.system_update),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onCheckForUpdates,
    ),
    ListTile(
      title: Text(l10n.settingsViewOnGitHub),
      subtitle: Text(l10n.settingsViewOnGitHubSubtitle),
      leading: const Icon(Icons.code),
      trailing: const Icon(Icons.open_in_new),
      onTap: onOpenGitHub,
    ),
  ];
}
