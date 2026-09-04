import 'package:flutter/material.dart';

import '../../constants/app_version.dart';
import '../../l10n/generated/app_localizations.dart';
import '../achievements_screen.dart';
import '../device_comparison_screen.dart';
import '../map/map_ui_actions.dart';
import '../map/map_ui_snapshot.dart';
import 'sections/about_section.dart';
import 'sections/app_device_section.dart';
import 'sections/backup_section.dart';
import 'sections/carpeater_section.dart';
import 'sections/data_management_section.dart';
import 'sections/diagnostics_section.dart';
import 'sections/discovery_section.dart';
import 'sections/feedback_section.dart';
import 'sections/location_section.dart';
import 'sections/map_display_section.dart';
import 'sections/online_map_section.dart';
import 'sections/statistics_section.dart';
import 'settings_dialogs.dart';
import 'settings_screen.dart';

typedef _SettingsCategoryBuilder = List<Widget> Function(
  BuildContext context,
  StateSetter setPageState,
  MapUiSnapshot ui,
);

enum _SettingsOverviewGroupId { map, sampling, app, data, system }

class _SettingsOverviewGroup {
  const _SettingsOverviewGroup({required this.title, required this.categories});

  final String title;
  final List<_SettingsCategory> categories;
}

class _SettingsCategory {
  const _SettingsCategory({
    required this.group,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final _SettingsOverviewGroupId group;
  final String title;
  final String subtitle;
  final IconData icon;
  final _SettingsCategoryBuilder builder;
}

/// Opens the map screen's settings overview.
///
/// Values render from [snapshot] (re-evaluated on every page build) and all
/// user changes go through [actions]; pages refresh their local state with
/// their own `setPageState` right after issuing a command.
void showMapSettings(
  BuildContext context, {
  required MapUiSnapshot Function() snapshot,
  required MapUiActions actions,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => SettingsScreen(
        version: appVersion,
        contentBuilder: (context, setPageState, scrollController) {
          final categories = _buildSettingsCategories(context, actions);

          return ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              for (final group in _buildSettingsOverviewGroups(
                context,
                categories,
              ))
                SettingsOverviewGroup(
                  title: group.title,
                  children: [
                    for (final category in group.categories)
                      SettingsCategoryTile(
                        title: category.title,
                        subtitle: category.subtitle,
                        icon: category.icon,
                        onTap: () => _openSettingsCategory(
                          context,
                          category: category,
                          snapshot: snapshot,
                          actions: actions,
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    ),
  );
}

void _closeSettingsPages(BuildContext context) {
  final navigator = Navigator.of(context);
  navigator.pop();
  navigator.pop();
}

void _openSettingsCategory(
  BuildContext context, {
  required _SettingsCategory category,
  required MapUiSnapshot Function() snapshot,
  required MapUiActions actions,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => SettingsScreen.category(
        title: category.title,
        contentBuilder: (context, setPageState, scrollController) {
          final children = category
              .builder(context, setPageState, snapshot())
              .toList();
          if (children.isNotEmpty && children.first is SettingsSectionHeader) {
            children.removeAt(0);
          }

          return ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [SettingsContentCard(children: children)],
          );
        },
      ),
    ),
  );
}

List<_SettingsOverviewGroup> _buildSettingsOverviewGroups(
  BuildContext context,
  List<_SettingsCategory> categories,
) {
  final l10n = AppLocalizations.of(context);

  return [
    for (final groupId in _SettingsOverviewGroupId.values)
      _SettingsOverviewGroup(
        title: switch (groupId) {
          _SettingsOverviewGroupId.map => l10n.settingsOverviewGroupMap,
          _SettingsOverviewGroupId.sampling =>
            l10n.settingsOverviewGroupSampling,
          _SettingsOverviewGroupId.app => l10n.settingsOverviewGroupApp,
          _SettingsOverviewGroupId.data => l10n.settingsOverviewGroupData,
          _SettingsOverviewGroupId.system => l10n.settingsOverviewGroupSystem,
        },
        categories: [
          for (final category in categories)
            if (category.group == groupId) category,
        ],
      ),
  ];
}

List<_SettingsCategory> _buildSettingsCategories(
  BuildContext context,
  MapUiActions actions,
) {
  final l10n = AppLocalizations.of(context);

  return [
    _SettingsCategory(
      group: _SettingsOverviewGroupId.map,
      title: l10n.settingsSectionMapDisplay,
      subtitle: l10n.settingsSectionMapDisplayDescription,
      icon: Icons.map_outlined,
      builder: (context, setPageState, ui) => buildMapDisplaySettings(
        context,
        values: MapDisplaySettingsValues(
          showCoverage: ui.showCoverage,
          mapLodEnabled: ui.mapLodEnabled,
          mapLodMinPrecision: ui.mapLodMinPrecision,
          mapLodMaxPrecision: ui.mapLodMaxPrecision,
          showSamples: ui.showSamples,
          fixedSampleMarkerSizeEnabled: ui.fixedSampleMarkerSizeEnabled,
          sampleMarkerRadius: ui.sampleMarkerRadius,
          sampleGeohashGrouping: ui.sampleGeohashGrouping,
          showEdges: ui.showEdges,
          showRepeaters: ui.showRepeaters,
          showPrivacyZones: ui.showPrivacyZones,
          showGpsExclusionZones: ui.showGpsExclusionZones,
          showGpsSamples: ui.showGpsSamples,
          showSuccessfulOnly: ui.showSuccessfulOnly,
          optimisticDisplay: ui.optimisticDisplay,
          showRouteTrail: ui.showRouteTrail,
          communityCoverageAvailable: ui.communityCoverageAvailable,
          showCommunityCoverage: ui.showCommunityCoverage,
          showHeatmap: ui.showHeatmap,
          showPredictionRings: ui.showPredictionRings,
        ),
        onChanged: (setting, value) {
          actions.setMapDisplaySetting(setting, value);
          setPageState(() {});
        },
        onMapLodMinPrecisionChanged: (value) {
          actions.setMapLodPrecision(min: value);
          setPageState(() {});
        },
        onMapLodMinPrecisionChangeEnd: actions.persistMapLodMin,
        onMapLodMaxPrecisionChanged: (value) {
          actions.setMapLodPrecision(max: value);
          setPageState(() {});
        },
        onMapLodMaxPrecisionChangeEnd: actions.persistMapLodMax,
        onSampleMarkerRadiusChanged: (value) {
          actions.setSampleMarkerRadius(value);
          setPageState(() {});
        },
        onSampleMarkerRadiusChangeEnd: actions.persistSampleMarkerRadius,
        onClearCommunityCoverage: () async {
          await actions.clearCommunityCoverage();
          setPageState(() {});
        },
      ),
    ),
    _SettingsCategory(
      group: _SettingsOverviewGroupId.map,
      title: l10n.settingsSectionLocation,
      subtitle: l10n.settingsSectionLocationDescription,
      icon: Icons.my_location_outlined,
      builder: (context, setPageState, ui) => buildLocationSettings(
        context,
        values: LocationSettingsValues(
          beaconDbWifiPositioning: ui.beaconDbWifiPositioning,
          showRadioPosition: ui.showRadioPosition,
          showDucting: ui.showDucting,
        ),
        onBeaconDbChanged: (value) {
          actions.setBeaconDbPositioning(value);
          setPageState(() {});
        },
        onOpenLocationQuality: actions.showLocationQuality,
        onRadioPositionChanged: (value) {
          actions.setShowRadioPosition(value);
          setPageState(() {});
        },
        onDuctingChanged: (value) {
          actions.setShowDucting(value);
          setPageState(() {});
        },
      ),
    ),
    _SettingsCategory(
      group: _SettingsOverviewGroupId.sampling,
      title: l10n.settingsSectionDiscovery,
      subtitle: l10n.settingsSectionDiscoveryDescription,
      icon: Icons.radar_outlined,
      builder: (context, setPageState, ui) => buildDiscoverySettings(
        context,
        values: DiscoverySettingsValues(
          timeoutSeconds: ui.discoveryTimeoutSeconds,
          responseCollectionMode: ui.responseCollectionMode,
          ignoredRepeaterPrefix: ui.ignoredRepeaterPrefix,
          includeOnlyRepeaters: ui.includeOnlyRepeaters,
          filterEdgesByWhitelist: ui.filterEdgesByWhitelist,
          pingMode: ui.pingMode,
          pingTimeInterval: ui.pingTimeInterval,
          pingIntervalDescription: pingIntervalDescription(
            context,
            ui.pingIntervalMeters,
          ),
          coverageResolutionDescription: coverageResolutionDescription(
            context,
            ui.coveragePrecision,
          ),
        ),
        onTimeoutChanged: (value) {
          actions.setDiscoveryTimeout(value);
          setPageState(() {});
        },
        onCollectionModeChanged: (value) {
          actions.setResponseCollectionMode(value);
          setPageState(() {});
        },
        onEditIgnoredRepeaters: () async {
          await actions.editIgnoredRepeaters();
          setPageState(() {});
        },
        onEditIncludedRepeaters: () async {
          await actions.editIncludedRepeaters();
          setPageState(() {});
        },
        onFilterEdgesChanged: (value) {
          actions.setFilterEdgesByWhitelist(value);
          setPageState(() {});
        },
        onPingModeChanged: (value) {
          actions.setPingMode(value);
          setPageState(() {});
        },
        onEditPingInterval: () async {
          await actions.editPingInterval();
          setPageState(() {});
        },
        onPingTimeIntervalChanged: (value) {
          actions.setPingTimeInterval(value);
          setPageState(() {});
        },
        onEditCoverageResolution: () async {
          await actions.editCoverageResolution();
          setPageState(() {});
        },
      ),
    ),
    _SettingsCategory(
      group: _SettingsOverviewGroupId.sampling,
      title: l10n.settingsSectionFeedback,
      subtitle: l10n.settingsSectionFeedbackDescription,
      icon: Icons.notifications_outlined,
      builder: (context, setPageState, ui) => buildFeedbackSettings(
        context,
        values: FeedbackSettingsValues(
          soundEnabled: ui.soundEnabled,
          vibrationEnabled: ui.vibrationEnabled,
          deadZoneAlertsEnabled: ui.deadZoneAlertsEnabled,
          newRepeaterAlertsEnabled: ui.newRepeaterAlertsEnabled,
          linkLossAlertsEnabled: ui.linkLossAlertsEnabled,
        ),
        onSoundChanged: (value) {
          actions.setSoundEnabled(value);
          setPageState(() {});
        },
        onVibrationChanged: (value) {
          actions.setVibrationEnabled(value);
          setPageState(() {});
        },
        onDeadZoneAlertsChanged: (value) {
          actions.setDeadZoneAlerts(value);
          setPageState(() {});
        },
        onNewRepeaterAlertsChanged: (value) {
          actions.setNewRepeaterAlerts(value);
          setPageState(() {});
        },
        onLinkLossAlertsChanged: (value) {
          actions.setLinkLossAlerts(value);
          setPageState(() {});
        },
      ),
    ),
    _SettingsCategory(
      group: _SettingsOverviewGroupId.sampling,
      title: l10n.settingsSectionCarpeater,
      subtitle: l10n.settingsSectionCarpeaterDescription,
      icon: Icons.cell_tower,
      builder: (context, setPageState, ui) => buildCarpeaterSettings(
        context,
        values: CarpeaterSettingsValues(
          enabled: ui.carpeaterEnabled,
          repeaterId: ui.carpeaterRepeaterId,
          password: ui.carpeaterPassword,
          interval: ui.carpeaterInterval,
          foundRepeaters: ui.foundRepeaters,
        ),
        onEnabledChanged: (value) {
          actions.setCarpeaterEnabled(value);
          setPageState(() {});
        },
        onRepeaterIdChanged: (value) {
          actions.setCarpeaterRepeaterId(value);
          setPageState(() {});
        },
        onPasswordChanged: (value) {
          actions.setCarpeaterPassword(value);
          setPageState(() {});
        },
        onIntervalChanged: (value) {
          actions.setCarpeaterInterval(value);
          setPageState(() {});
        },
      ),
    ),
    _SettingsCategory(
      group: _SettingsOverviewGroupId.app,
      title: l10n.settingsSectionAppDevice,
      subtitle: l10n.settingsSectionAppDeviceDescription,
      icon: Icons.tune,
      builder: (context, setPageState, ui) => buildAppDeviceSettings(
        context,
        values: AppDeviceSettingsValues(
          deviceName: ui.deviceName,
          keepScreenOn: ui.keepScreenOn,
          batterySaverEnabled: ui.batterySaverEnabled,
          lockRotationNorth: ui.lockRotationNorth,
          currentLocationMarkerStyle: ui.currentLocationMarkerStyle,
          interfaceThemeDescription: ui.interfaceThemeDescription,
          mapThemeDescription: ui.mapThemeDescription,
          localePreferenceDescription: ui.localePreferenceDescription,
          loraConnected: ui.loraConnected,
          repeaterCount: ui.repeaterCount,
          colorMode: ui.colorMode,
          distanceUnit: ui.distanceUnit,
          fuelUnit: ui.fuelUnit,
          colorBlindMode: ui.colorBlindMode,
        ),
        onDeviceNameChanged: (value) async {
          await actions.setDeviceName(value);
          setPageState(() {});
        },
        onKeepScreenOnChanged: (value) {
          actions.setKeepScreenOn(value);
          setPageState(() {});
        },
        onBatterySaverChanged: (value) {
          actions.setBatterySaverEnabled(value);
          setPageState(() {});
        },
        onLockRotationNorthChanged: (value) {
          actions.setLockRotationNorth(value);
          setPageState(() {});
        },
        onCurrentLocationMarkerStyleChanged: (value) {
          actions.setCurrentLocationMarkerStyle(value);
          setPageState(() {});
        },
        onCalibrateCompass: actions.calibrateCompass,
        onSelectInterfaceTheme: actions.selectInterfaceTheme,
        onSelectMapTheme: actions.selectMapTheme,
        onSelectLanguage: actions.selectLanguage,
        onScanForRepeaters: actions.scanForRepeaters,
        onRefreshContacts: actions.refreshContacts,
        onColorModeChanged: (value) {
          actions.setColorMode(value);
          setPageState(() {});
        },
        onDistanceUnitChanged: (value) {
          actions.setDistanceUnit(value);
          setPageState(() {});
        },
        onFuelUnitChanged: (value) {
          actions.setFuelUnit(value);
          setPageState(() {});
        },
        onColorBlindModeChanged: (value) {
          actions.setColorBlindMode(value);
          setPageState(() {});
        },
      ),
    ),
    _SettingsCategory(
      group: _SettingsOverviewGroupId.map,
      title: l10n.settingsSectionOnlineMap,
      subtitle: l10n.settingsSectionOnlineMapDescription,
      icon: Icons.cloud_outlined,
      builder: (context, _, ui) => buildOnlineMapSettings(
        context,
        onUploadSamples: actions.uploadSamples,
        onManageUploadSites: actions.manageUploadSites,
      ),
    ),
    _SettingsCategory(
      group: _SettingsOverviewGroupId.app,
      title: l10n.settingsSectionStatistics,
      subtitle: l10n.settingsSectionStatisticsDescription,
      icon: Icons.query_stats,
      builder: (context, setPageState, ui) => buildStatisticsSettings(
        context,
        values: actions.loadDrivingStatistics(),
        sessionMeters: ui.sessionDistanceMeters,
        distanceUnit: ui.distanceUnit,
        fuelUnit: ui.fuelUnit,
        onResetDistance: () async {
          await actions.resetTotalDistance();
          setPageState(() {});
        },
        onVehicleMpgChanged: (value) async {
          await actions.setVehicleMpg(value);
          setPageState(() {});
        },
        onGasPriceChanged: (value) async {
          await actions.setGasPrice(value);
          setPageState(() {});
        },
      ),
    ),
    _SettingsCategory(
      group: _SettingsOverviewGroupId.data,
      title: l10n.settingsSectionDataManagement,
      subtitle: l10n.settingsSectionDataManagementDescription,
      icon: Icons.storage_outlined,
      builder: (context, setPageState, ui) => buildDataManagementSettings(
        context,
        values: DataManagementSettingsValues(
          communityCoverageAvailable: ui.communityCoverageAvailable,
          sessionFiltered: ui.sessionFiltered,
          includeOnlyRepeaters: ui.includeOnlyRepeaters,
          activeSourceFilter: ui.activeSourceFilter,
          plannedMarkerCount: ui.plannedMarkerCount,
          privacyZoneCount: ui.privacyZoneCount,
        ),
        onOpenAnalytics: actions.openAnalytics,
        onOpenAchievements: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const AchievementsScreen(),
          ),
        ),
        onOpenDeviceComparison: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const DeviceComparisonScreen(),
          ),
        ),
        onDownloadCommunityCoverage: actions.downloadCommunityCoverage,
        onOpenSessionHistory: actions.openSessionHistory,
        onClearSessionFilter: () async {
          await actions.clearSessionFilter();
          setPageState(() {});
        },
        onExportData: actions.exportData,
        onImportData: actions.importData,
        onShareCoverageMap: actions.shareCoverageMap,
        onOpenRepeaterFilter: actions.showRepeaterFilterPicker,
        onClearRepeaterFilter: () async {
          await actions.clearRepeaterFilter();
          setPageState(() {});
        },
        onOpenSourceFilter: () async {
          await actions.selectSourceFilter();
          setPageState(() {});
        },
        onClearSourceFilter: () async {
          await actions.clearSourceFilter();
          setPageState(() {});
        },
        onFindCoverageGaps: () {
          _closeSettingsPages(context);
          actions.findCoverageGaps();
        },
        onEnableDeleteMode: () {
          _closeSettingsPages(context);
          actions.enableDeleteMode();
        },
        onClearPlannedMarkers: () async {
          await actions.clearPlannedMarkers();
          setPageState(() {});
        },
        onAddPrivacyZone: () async {
          await actions.addPrivacyZone();
          setPageState(() {});
        },
        onClearPrivacyZones: () async {
          await actions.clearPrivacyZones();
          setPageState(() {});
        },
        onClearMap: actions.clearMapData,
        onDownloadOfflineTiles: actions.downloadOfflineTiles,
        onClearTileCache: () async {
          await actions.clearTileCache();
          setPageState(() {});
        },
      ),
    ),
    _SettingsCategory(
      group: _SettingsOverviewGroupId.data,
      title: l10n.settingsSectionBackup,
      subtitle: l10n.settingsSectionBackupDescription,
      icon: Icons.settings_backup_restore,
      builder: (context, _, ui) => buildBackupSettings(
        context,
        onExportSettings: actions.exportSettings,
        onImportSettings: actions.importSettings,
        onExportDatabase: actions.exportDatabase,
        onImportDatabase: actions.importDatabase,
      ),
    ),
    _SettingsCategory(
      group: _SettingsOverviewGroupId.system,
      title: l10n.settingsSectionDiagnostics,
      subtitle: l10n.settingsSectionDiagnosticsDescription,
      icon: Icons.bug_report_outlined,
      builder: (context, _, ui) => buildDiagnosticsSettings(
        context,
        samples: ui.samples,
        onOpenDebugDiagnostics: actions.openDebugDiagnostics,
      ),
    ),
    _SettingsCategory(
      group: _SettingsOverviewGroupId.system,
      title: l10n.settingsSectionAbout,
      subtitle: l10n.settingsSectionAboutDescription,
      icon: Icons.info_outline,
      builder: (context, _, ui) => buildAboutSettings(
        context,
        version: appVersion,
        onCheckForUpdates: actions.checkForUpdates,
        onOpenGitHub: actions.openGitHub,
      ),
    ),
  ];
}
