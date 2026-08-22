import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../widgets/settings_section_header.dart';

typedef DataManagementAction = FutureOr<void> Function();

class DataManagementSettingsValues {
  const DataManagementSettingsValues({
    required this.communityCoverageAvailable,
    required this.sessionFiltered,
    required this.includeOnlyRepeaters,
    required this.activeSourceFilter,
    required this.plannedMarkerCount,
    required this.privacyZoneCount,
  });

  final bool communityCoverageAvailable;
  final bool sessionFiltered;
  final String? includeOnlyRepeaters;
  final String? activeSourceFilter;
  final int plannedMarkerCount;
  final int privacyZoneCount;
}

List<Widget> buildDataManagementSettings(
  BuildContext context, {
  required DataManagementSettingsValues values,
  required DataManagementAction onOpenAnalytics,
  required DataManagementAction onOpenAchievements,
  required DataManagementAction onOpenDeviceComparison,
  required DataManagementAction onDownloadCommunityCoverage,
  required DataManagementAction onOpenSessionHistory,
  required DataManagementAction onClearSessionFilter,
  required DataManagementAction onExportData,
  required DataManagementAction onImportData,
  required DataManagementAction onShareCoverageMap,
  required DataManagementAction onOpenRepeaterFilter,
  required DataManagementAction onClearRepeaterFilter,
  required DataManagementAction onOpenSourceFilter,
  required DataManagementAction onClearSourceFilter,
  required DataManagementAction onFindCoverageGaps,
  required DataManagementAction onEnableDeleteMode,
  required DataManagementAction onClearPlannedMarkers,
  required DataManagementAction onAddPrivacyZone,
  required DataManagementAction onClearPrivacyZones,
  required DataManagementAction onClearMap,
  required DataManagementAction onDownloadOfflineTiles,
  required DataManagementAction onClearTileCache,
}) {
  final l10n = AppLocalizations.of(context);
  final includeOnlyRepeaters = values.includeOnlyRepeaters;
  final hasRepeaterFilter = includeOnlyRepeaters?.isNotEmpty ?? false;

  return [
    SettingsSectionHeader(
      title: l10n.settingsSectionDataManagement,
      icon: Icons.storage_outlined,
    ),
    ListTile(
      title: Text(l10n.settingsAnalytics),
      subtitle: Text(l10n.settingsAnalyticsSubtitle),
      leading: const Icon(Icons.analytics),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => onOpenAnalytics(),
    ),
    ListTile(
      title: Text(l10n.settingsAchievements),
      subtitle: Text(l10n.settingsAchievementsSubtitle),
      leading: const Icon(Icons.emoji_events),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => onOpenAchievements(),
    ),
    ListTile(
      title: Text(l10n.settingsDeviceComparison),
      subtitle: Text(l10n.settingsDeviceComparisonSubtitle),
      leading: const Icon(Icons.devices),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => onOpenDeviceComparison(),
    ),
    ListTile(
      title: Text(l10n.settingsDownloadCommunityCoverage),
      subtitle: Text(
        values.communityCoverageAvailable
            ? l10n.settingsCommunityCoverageCached
            : l10n.settingsPullCoverageFromWeb,
      ),
      leading: const Icon(Icons.cloud_download),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => onDownloadCommunityCoverage(),
    ),
    ListTile(
      title: Text(l10n.settingsSessionHistory),
      subtitle: Text(
        values.sessionFiltered
            ? l10n.settingsFilteringBySession
            : l10n.settingsViewPastSessions,
      ),
      leading: const Icon(Icons.history),
      trailing: values.sessionFiltered
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () => onClearSessionFilter(),
              tooltip: l10n.settingsClearFilterTooltip,
            )
          : const Icon(Icons.arrow_forward),
      onTap: () => onOpenSessionHistory(),
    ),
    ListTile(
      title: Text(l10n.settingsExportData),
      subtitle: Text(l10n.settingsExportDataSubtitle),
      leading: const Icon(Icons.upload),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => onExportData(),
    ),
    ListTile(
      title: Text(l10n.settingsImportData),
      subtitle: Text(l10n.settingsImportDataSubtitle),
      leading: const Icon(Icons.download),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => onImportData(),
    ),
    ListTile(
      title: Text(l10n.settingsShareCoverageMap),
      subtitle: Text(l10n.settingsShareCoverageMapSubtitle),
      leading: const Icon(Icons.share),
      onTap: () => onShareCoverageMap(),
    ),
    ListTile(
      title: Text(l10n.settingsFilterByRepeater),
      subtitle: Text(
        hasRepeaterFilter
            ? l10n.settingsFilteringRepeater(includeOnlyRepeaters!)
            : l10n.settingsShowCoverageFromRepeater,
      ),
      leading: const Icon(Icons.filter_alt),
      trailing: hasRepeaterFilter
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () => onClearRepeaterFilter(),
            )
          : const Icon(Icons.arrow_forward),
      onTap: () => onOpenRepeaterFilter(),
    ),
    ListTile(
      title: Text(l10n.settingsFilterBySource),
      subtitle: Text(
        values.activeSourceFilter != null
            ? l10n.settingsShowingSource(values.activeSourceFilter!)
            : l10n.settingsFilterByDeviceOperator,
      ),
      leading: const Icon(Icons.people),
      trailing: values.activeSourceFilter != null
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () => onClearSourceFilter(),
            )
          : const Icon(Icons.arrow_forward),
      onTap: () => onOpenSourceFilter(),
    ),
    ListTile(
      title: Text(l10n.settingsFindCoverageGaps),
      subtitle: Text(l10n.settingsFindCoverageGapsSubtitle),
      leading: const Icon(Icons.location_searching),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => onFindCoverageGaps(),
    ),
    ListTile(
      title: Text(l10n.settingsDeleteMode),
      subtitle: Text(l10n.settingsDeleteModeSubtitle),
      leading: const Icon(Icons.delete_sweep, color: Colors.orange),
      onTap: () => onEnableDeleteMode(),
    ),
    ListTile(
      title: Text(l10n.settingsPlannedRepeaters),
      subtitle: Text(
        l10n.settingsPlannedMarkersSubtitle(values.plannedMarkerCount),
      ),
      leading: const Icon(Icons.add_location, color: Colors.amber),
      trailing: values.plannedMarkerCount > 0
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.red, size: 20),
              onPressed: () => onClearPlannedMarkers(),
            )
          : null,
    ),
    ListTile(
      title: Text(l10n.settingsPrivacyZones),
      subtitle: Text(
        l10n.settingsPrivacyZonesSubtitle(values.privacyZoneCount),
      ),
      leading: const Icon(Icons.shield, color: Colors.blueGrey),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => onAddPrivacyZone(),
    ),
    if (values.privacyZoneCount > 0)
      ListTile(
        title: Text(l10n.settingsClearPrivacyZones),
        subtitle: Text(l10n.settingsRemoveAllZones(values.privacyZoneCount)),
        leading: const Icon(Icons.shield_outlined, color: Colors.red),
        onTap: () => onClearPrivacyZones(),
      ),
    ListTile(
      title: Text(l10n.settingsClearMap),
      subtitle: Text(l10n.settingsClearMapSubtitle),
      leading: const Icon(Icons.delete, color: Colors.red),
      onTap: () => onClearMap(),
    ),
    ListTile(
      title: Text(l10n.settingsDownloadOfflineTiles),
      subtitle: Text(l10n.settingsDownloadOfflineTilesSubtitle),
      leading: const Icon(Icons.download_for_offline),
      onTap: () => onDownloadOfflineTiles(),
    ),
    ListTile(
      title: Text(l10n.settingsClearTileCache),
      subtitle: Text(l10n.settingsClearTileCacheSubtitle),
      leading: const Icon(Icons.cached, color: Colors.orange),
      onTap: () => onClearTileCache(),
    ),
  ];
}
