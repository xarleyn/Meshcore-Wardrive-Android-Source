import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../widgets/settings_section_header.dart';

List<Widget> buildOnlineMapSettings(
  BuildContext context, {
  required VoidCallback onUploadSamples,
  required VoidCallback onManageUploadSites,
}) {
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
      onTap: onUploadSamples,
    ),
    ListTile(
      title: Text(l10n.settingsManageUploadSites),
      subtitle: Text(l10n.settingsManageUploadSitesSubtitle),
      leading: const Icon(Icons.dns),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onManageUploadSites,
    ),
  ];
}
