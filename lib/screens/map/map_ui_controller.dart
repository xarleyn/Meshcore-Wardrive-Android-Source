import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/impossible_zone.dart';
import '../../models/location_quality_settings.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/screen_wake_service.dart';
import '../../services/settings_service.dart';
import '../../services/sound_service.dart';
import '../../services/upload_service.dart';
import '../../utils/session_map_view.dart';
import '../../widgets/confirm_dialog.dart';
import '../settings/sections/location_quality_section.dart';
import '../settings/sections/map_display_section.dart';
import '../settings/sections/statistics_section.dart';
import '../settings/settings_dialogs.dart';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

import '../analytics_screen.dart';
import 'dialogs/theme_flows.dart';
import 'map_screen_controller.dart';
import 'map_ui_actions.dart';

/// Applies settings-page commands to the map screen.
///
/// Owns no screen state: values render from [MapUiSnapshot], mutations go
/// through the injected screen hooks, persistence goes through
/// [settingsService], and screen-specific flows (connection, uploads, data
/// I/O, entity dialogs) are injected as closures.
class MapUiController implements MapUiActions {
  const MapUiController({
    required this.context,
    required this.onShowSnackBar,
    required this.updateState,
    required this.settingsService,
    required this.databaseService,
    required this.locationService,
    required this.uploadService,
    required this.mapDataController,
    required this.setDisplayFlag,
    required this.setSampleMarkerRadiusFlag,
    required this.setMapLodPrecisionBounds,
    required this.mapLodMinPrecision,
    required this.mapLodMaxPrecision,
    required this.setBeaconDbFlag,
    required this.setShowRadioPositionFlag,
    required this.setShowDuctingFlag,
    required this.setCurrentDuctingRisk,
    required this.setDiscoveryTimeoutFlag,
    required this.setResponseCollectionModeFlag,
    required this.setIgnoredRepeaterPrefixFlag,
    required this.ignoredRepeaterPrefix,
    required this.setIncludeOnlyRepeatersFlag,
    required this.includeOnlyRepeaters,
    required this.setFilterEdgesFlag,
    required this.setPingModeFlag,
    required this.setPingTimeIntervalFlag,
    required this.setPingIntervalMetersFlag,
    required this.setCoveragePrecisionFlag,
    required this.coveragePrecision,
    required this.setSoundFlag,
    required this.setVibrationFlag,
    required this.setDeadZoneAlertsFlag,
    required this.setNewRepeaterAlertsFlag,
    required this.setLinkLossAlertsFlag,
    required this.setCarpeaterEnabledFlag,
    required this.syncAutoPingFlag,
    required this.setCarpeaterRepeaterIdFlag,
    required this.setCarpeaterPasswordFlag,
    required this.setCarpeaterIntervalFlag,
    required this.setKeepScreenOnFlag,
    required this.setBatterySaverFlag,
    required this.setLockRotationFlag,
    required this.setMarkerStyleFlag,
    required this.setColorModeFlag,
    required this.setDistanceUnitFlag,
    required this.setFuelUnitFlag,
    required this.setColorBlindModeFlag,
    required this.setSessionMapView,
    required this.setActiveSourceFilter,
    required this.activeSourceFilter,
    required this.hideCommunityCoverage,
    required this.setDeleteMode,
    required this.setLocationQualitySettingsFlag,
    required this.locationQualitySettings,
    required this.impossibleZones,
    required this.newZoneCenter,
    required this.tileCacheStore,
    required this.samples,
    required this.currentPosition,
    required this.plannedMarkers,
    required this.privacyZones,
    required this.mapThemeMode,
    required this.setMapThemeModeFlag,
    required this.requestHeatmapRebuild,
    required this.resetMapRotation,
    required this.syncCompassSubscription,
    required this.requestWifiScanThrottlingDisabled,
    required this.loadMarkers,
    required this.loadPrivacyZones,
    required this.loadImpossibleZones,
    required this.reloadSamples,
    required this.applyRepeaterFilter,
    required this.addPrivacyZoneAt,
    required this.calibrateCompassFlow,
    required this.scanForRepeatersFlow,
    required this.refreshContactsFlow,
    required this.exportDataFlow,
    required this.importDataFlow,
    required this.exportSettingsFlow,
    required this.importSettingsFlow,
    required this.exportDatabaseFlow,
    required this.importDatabaseFlow,
    required this.clearMapDataFlow,
    required this.uploadSamplesFlow,
    required this.manageUploadSitesFlow,
    required this.downloadCommunityCoverageFlow,
    required this.downloadOfflineTilesFlow,
    required this.shareCoverageMapFlow,
    required this.showRepeaterFilterPickerFlow,
    required this.findCoverageGapsFlow,
    required this.openSessionHistoryFlow,
    required this.openDebugDiagnosticsFlow,
    required this.checkForUpdatesFlow,
    required this.openGitHubFlow,
  });

  /// Screen context used for mounted checks, localization, and dialogs.
  final BuildContext context;

  /// Shows a transient message; the owner guards this callback with its own
  /// mounted check.
  final void Function(String message) onShowSnackBar;

  /// Applies a synchronous screen-state mutation (guarded `setState`).
  final void Function(VoidCallback mutate) updateState;

  final SettingsService settingsService;
  final DatabaseService databaseService;
  final LocationService locationService;
  final UploadService uploadService;
  final MapScreenController mapDataController;

  // Screen state mutators.
  final void Function(MapDisplaySetting setting, bool value) setDisplayFlag;
  final void Function(double value) setSampleMarkerRadiusFlag;
  final void Function({int? min, int? max}) setMapLodPrecisionBounds;
  final int Function() mapLodMinPrecision;
  final int Function() mapLodMaxPrecision;
  final void Function(bool value) setBeaconDbFlag;
  final void Function(bool value) setShowRadioPositionFlag;
  final void Function(bool value) setShowDuctingFlag;
  final void Function(String risk) setCurrentDuctingRisk;
  final void Function(int seconds) setDiscoveryTimeoutFlag;
  final void Function(String mode) setResponseCollectionModeFlag;
  final void Function(String? prefix) setIgnoredRepeaterPrefixFlag;
  final String? Function() ignoredRepeaterPrefix;
  final void Function(String? id) setIncludeOnlyRepeatersFlag;
  final String? Function() includeOnlyRepeaters;
  final void Function(bool value) setFilterEdgesFlag;
  final void Function(String mode) setPingModeFlag;
  final void Function(int minutes) setPingTimeIntervalFlag;
  final void Function(double meters) setPingIntervalMetersFlag;
  final void Function(int precision) setCoveragePrecisionFlag;
  final int Function() coveragePrecision;
  final void Function(bool value) setSoundFlag;
  final void Function(bool value) setVibrationFlag;
  final void Function(bool value) setDeadZoneAlertsFlag;
  final void Function(bool value) setNewRepeaterAlertsFlag;
  final void Function(bool value) setLinkLossAlertsFlag;
  final void Function(bool value) setCarpeaterEnabledFlag;
  final void Function() syncAutoPingFlag;
  final void Function(String? id) setCarpeaterRepeaterIdFlag;
  final void Function(String? password) setCarpeaterPasswordFlag;
  final void Function(int minutes) setCarpeaterIntervalFlag;
  final void Function(bool value) setKeepScreenOnFlag;
  final void Function(bool value) setBatterySaverFlag;
  final void Function(bool value) setLockRotationFlag;
  final void Function(CurrentLocationMarkerStyle style) setMarkerStyleFlag;
  final void Function(String mode) setColorModeFlag;
  final void Function(String unit) setDistanceUnitFlag;
  final void Function(String unit) setFuelUnitFlag;
  final void Function(String mode) setColorBlindModeFlag;
  final void Function(SessionMapView view) setSessionMapView;
  final void Function(String? source) setActiveSourceFilter;
  final String? Function() activeSourceFilter;
  final void Function() hideCommunityCoverage;
  final void Function(bool value) setDeleteMode;
  final void Function(LocationQualitySettings settings)
  setLocationQualitySettingsFlag;
  final LocationQualitySettings Function() locationQualitySettings;
  final List<ImpossibleZone> Function() impossibleZones;
  final LatLng Function() newZoneCenter;
  final CacheStore? Function() tileCacheStore;
  final List<Sample> Function() samples;
  final LatLng? Function() currentPosition;
  final List<Map<String, dynamic>> Function() plannedMarkers;
  final List<Map<String, dynamic>> Function() privacyZones;
  final MapThemeMode Function() mapThemeMode;
  final void Function(MapThemeMode mode) setMapThemeModeFlag;

  // Screen lifecycle and flow hooks.
  final void Function() requestHeatmapRebuild;
  final void Function() resetMapRotation;
  final void Function() syncCompassSubscription;
  final Future<bool> Function() requestWifiScanThrottlingDisabled;
  final Future<void> Function() loadMarkers;
  final Future<void> Function() loadPrivacyZones;
  final Future<void> Function() loadImpossibleZones;
  final Future<void> Function() reloadSamples;
  final Future<void> Function(String? repeaterId) applyRepeaterFilter;
  final Future<void> Function(LatLng center) addPrivacyZoneAt;
  final Future<void> Function() calibrateCompassFlow;
  final Future<void> Function() scanForRepeatersFlow;
  final Future<void> Function() refreshContactsFlow;
  final Future<void> Function() exportDataFlow;
  final Future<void> Function() importDataFlow;
  final Future<void> Function() exportSettingsFlow;
  final Future<void> Function() importSettingsFlow;
  final Future<void> Function() exportDatabaseFlow;
  final Future<void> Function() importDatabaseFlow;
  final Future<void> Function() clearMapDataFlow;
  final Future<void> Function() uploadSamplesFlow;
  final Future<void> Function() manageUploadSitesFlow;
  final Future<void> Function() downloadCommunityCoverageFlow;
  final Future<void> Function() downloadOfflineTilesFlow;
  final Future<void> Function() shareCoverageMapFlow;
  final void Function() showRepeaterFilterPickerFlow;
  final Future<void> Function() findCoverageGapsFlow;
  final void Function() openSessionHistoryFlow;
  final void Function() openDebugDiagnosticsFlow;
  final Future<void> Function() checkForUpdatesFlow;
  final Future<void> Function() openGitHubFlow;

  ThemeFlow get _themeFlow => ThemeFlow(
    context: context,
    locationService: locationService,
    settingsService: settingsService,
    mapThemeMode: mapThemeMode,
    onMapThemeModeChanged: (mode) =>
        updateState(() => setMapThemeModeFlag(mode)),
  );

  @override
  Future<void> setMapDisplaySetting(
    MapDisplaySetting setting,
    bool value,
  ) async {
    updateState(() => setDisplayFlag(setting, value));
    switch (setting) {
      case MapDisplaySetting.coverage:
        await settingsService.setShowCoverage(value);
      case MapDisplaySetting.mapLod:
        await settingsService.setMapLodEnabled(value);
      case MapDisplaySetting.samples:
        await settingsService.setShowSamples(value);
      case MapDisplaySetting.fixedSampleMarkerSize:
        await settingsService.setFixedSampleMarkerSizeEnabled(value);
      case MapDisplaySetting.sampleGeohashGrouping:
        await settingsService.setSampleGeohashGrouping(value);
      case MapDisplaySetting.edges:
        await settingsService.setShowEdges(value);
      case MapDisplaySetting.repeaters:
        await settingsService.setShowRepeaters(value);
      case MapDisplaySetting.privacyZones:
        await settingsService.setShowPrivacyZones(value);
      case MapDisplaySetting.gpsExclusionZones:
        await settingsService.setShowGpsExclusionZones(value);
      case MapDisplaySetting.gpsSamples:
        await settingsService.setShowGpsSamples(value);
      case MapDisplaySetting.successfulOnly:
        await settingsService.setShowSuccessfulOnly(value);
      case MapDisplaySetting.optimisticDisplay:
        await settingsService.setOptimisticDisplay(value);
        // Optimism changes the aggregated cell colors, so rebuild them now.
        mapDataController.invalidate();
        await reloadSamples();
      case MapDisplaySetting.routeTrail:
        await settingsService.setShowRouteTrail(value);
      case MapDisplaySetting.communityCoverage:
        break;
      case MapDisplaySetting.heatmap:
        await settingsService.setShowHeatmap(value);
        requestHeatmapRebuild();
      case MapDisplaySetting.predictionRings:
        await settingsService.setShowPredictionRings(value);
    }
  }

  @override
  void setMapLodPrecision({int? min, int? max}) =>
      updateState(() => setMapLodPrecisionBounds(min: min, max: max));

  @override
  Future<void> persistMapLodMin(int value) async {
    await settingsService.setMapLodMinPrecision(value);
    if (mapLodMaxPrecision() < value) {
      await settingsService.setMapLodMaxPrecision(value);
    }
  }

  @override
  Future<void> persistMapLodMax(int value) async {
    await settingsService.setMapLodMaxPrecision(value);
    if (mapLodMinPrecision() > value) {
      await settingsService.setMapLodMinPrecision(value);
    }
  }

  @override
  void setSampleMarkerRadius(double value) =>
      updateState(() => setSampleMarkerRadiusFlag(value));

  @override
  Future<void> persistSampleMarkerRadius(double value) =>
      settingsService.setSampleMarkerRadius(value);

  @override
  Future<void> clearCommunityCoverage() async {
    await uploadService.clearCachedCoverage();
    updateState(hideCommunityCoverage);
    if (!context.mounted) return;
    onShowSnackBar(
      AppLocalizations.of(context).settingsCommunityCoverageCleared,
    );
  }

  @override
  Future<void> setBeaconDbPositioning(bool value) async {
    updateState(() => setBeaconDbFlag(value));
    await settingsService.setBeaconDbWifiPositioning(value);
    locationService.setWifiPositioningEnabled(value);
    if (!value || !context.mounted) return;
    onShowSnackBar(AppLocalizations.of(context).settingsBeaconDbEnabledSnack);
    await requestWifiScanThrottlingDisabled();
  }

  @override
  Future<void> showLocationQuality() {
    return showLocationQualitySettings(
      context,
      settings: locationQualitySettings,
      zones: impossibleZones,
      newZoneCenter: newZoneCenter,
      onSettingsChanged: (settings) async {
        await settingsService.setLocationQualitySettings(settings);
        if (!context.mounted) return;
        updateState(() => setLocationQualitySettingsFlag(settings));
        locationService.setLocationQualitySettings(settings);
      },
      onResetSettings: () async {
        const settings = LocationQualitySettings();
        await settingsService.setLocationQualitySettings(settings);
        if (!context.mounted) return;
        updateState(() => setLocationQualitySettingsFlag(settings));
        locationService.setLocationQualitySettings(settings);
        onShowSnackBar(
          AppLocalizations.of(context).settingsLocationQualityResetSnack,
        );
      },
      onAddZone: (draft) async {
        await databaseService.addImpossibleZone(
          draft.center.latitude,
          draft.center.longitude,
          draft.radiusMeters,
          draft.label,
        );
        await loadImpossibleZones();
        if (!context.mounted) return;
        onShowSnackBar(
          AppLocalizations.of(context).settingsImpossibleZoneAdded,
        );
      },
      onDeleteZone: (id) async {
        await databaseService.deleteImpossibleZone(id);
        await loadImpossibleZones();
      },
      onClearZones: () async {
        for (final zone in impossibleZones()) {
          final id = zone.id;
          if (id != null) await databaseService.deleteImpossibleZone(id);
        }
        await loadImpossibleZones();
      },
    );
  }

  @override
  Future<void> setShowRadioPosition(bool value) async {
    updateState(() => setShowRadioPositionFlag(value));
    await settingsService.setShowRadioPosition(value);
  }

  @override
  Future<void> setShowDucting(bool value) async {
    updateState(() => setShowDuctingFlag(value));
    await settingsService.setShowDucting(value);
    locationService.setDuctingEnabled(value);
    if (!value) return;
    final risk = await locationService.ductingService.getLatestRisk();
    updateState(() => setCurrentDuctingRisk(risk));
  }

  @override
  Future<void> setDiscoveryTimeout(int seconds) async {
    updateState(() => setDiscoveryTimeoutFlag(seconds));
    await settingsService.setDiscoveryTimeout(seconds);
  }

  @override
  Future<void> setResponseCollectionMode(String mode) async {
    updateState(() => setResponseCollectionModeFlag(mode));
    await settingsService.setResponseCollectionMode(mode);
  }

  @override
  Future<void> editIgnoredRepeaters() async {
    final l10n = AppLocalizations.of(context);
    final result = await showIgnoredRepeaterDialog(
      context,
      currentValue: ignoredRepeaterPrefix(),
    );
    if (result == null || !context.mounted) return;
    updateState(() => setIgnoredRepeaterPrefixFlag(result.value));
    locationService.loraCompanion.setIgnoredRepeaterPrefix(result.value);
    await settingsService.setIgnoredRepeaterPrefix(result.value);
    onShowSnackBar(l10n.settingsRepeaterPrefixUpdated);
  }

  @override
  Future<void> editIncludedRepeaters() async {
    final l10n = AppLocalizations.of(context);
    final result = await showIncludedRepeaterDialog(
      context,
      currentValue: includeOnlyRepeaters(),
    );
    if (result == null || !context.mounted) return;
    updateState(() => setIncludeOnlyRepeatersFlag(result.value));
    await settingsService.setIncludeOnlyRepeaters(result.value);
    onShowSnackBar(l10n.settingsRepeaterWhitelistUpdated);
  }

  @override
  Future<void> setFilterEdgesByWhitelist(bool value) async {
    updateState(() => setFilterEdgesFlag(value));
    await settingsService.setFilterEdgesByWhitelist(value);
  }

  @override
  Future<void> setPingMode(String mode) async {
    updateState(() => setPingModeFlag(mode));
    await settingsService.setPingMode(mode);
    locationService.setPingMode(mode);
  }

  @override
  Future<void> editPingInterval() async {
    final l10n = AppLocalizations.of(context);
    final interval = await showPingIntervalDialog(context);
    if (interval == null || !context.mounted) return;
    updateState(() => setPingIntervalMetersFlag(interval));
    locationService.setPingInterval(interval);
    await settingsService.setPingInterval(interval);
    if (!context.mounted) return;
    onShowSnackBar(
      l10n.settingsPingIntervalSet(pingIntervalDescription(context, interval)),
    );
  }

  @override
  Future<void> setPingTimeInterval(int minutes) async {
    updateState(() => setPingTimeIntervalFlag(minutes));
    await settingsService.setPingTimeInterval(minutes);
    locationService.setPingTimeInterval(minutes);
  }

  @override
  Future<void> editCoverageResolution() async {
    final l10n = AppLocalizations.of(context);
    final precision = await showCoverageResolutionDialog(context);
    if (precision == null || !context.mounted) return;
    updateState(() => setCoveragePrecisionFlag(precision));
    await settingsService.setCoveragePrecision(precision);
    mapDataController.invalidate();
    await reloadSamples();
    if (!context.mounted) return;
    onShowSnackBar(
      l10n.settingsCoverageResolutionSet(
        coverageResolutionDescription(context, precision),
      ),
    );
  }

  @override
  Future<void> setSoundEnabled(bool value) async {
    updateState(() => setSoundFlag(value));
    await settingsService.setSoundEnabled(value);
    SoundService().setEnabled(value);
  }

  @override
  Future<void> setVibrationEnabled(bool value) async {
    updateState(() => setVibrationFlag(value));
    await settingsService.setVibrationEnabled(value);
    SoundService().setVibrationEnabled(value);
  }

  @override
  Future<void> setDeadZoneAlerts(bool value) async {
    updateState(() => setDeadZoneAlertsFlag(value));
    await settingsService.setDeadZoneAlertsEnabled(value);
  }

  @override
  Future<void> setNewRepeaterAlerts(bool value) async {
    updateState(() => setNewRepeaterAlertsFlag(value));
    await settingsService.setNewRepeaterAlertsEnabled(value);
    locationService.loraCompanion.setNewRepeaterAlertsEnabled(value);
  }

  @override
  Future<void> setLinkLossAlerts(bool value) async {
    updateState(() => setLinkLossAlertsFlag(value));
    await settingsService.setLinkLossAlertsEnabled(value);
    locationService.setLinkLossAlertsEnabled(value);
  }

  @override
  Future<void> setCarpeaterEnabled(bool value) async {
    updateState(() => setCarpeaterEnabledFlag(value));
    await settingsService.setCarpeaterEnabled(value);
    locationService.setCarpeaterMode(value);
    updateState(syncAutoPingFlag);
  }

  @override
  Future<void> setCarpeaterRepeaterId(String? id) async {
    updateState(() => setCarpeaterRepeaterIdFlag(id));
    await settingsService.setCarpeaterRepeaterId(id);
  }

  @override
  Future<void> setCarpeaterPassword(String? password) async {
    updateState(() => setCarpeaterPasswordFlag(password));
    await settingsService.setCarpeaterPassword(password);
  }

  @override
  Future<void> setCarpeaterInterval(int minutes) async {
    updateState(() => setCarpeaterIntervalFlag(minutes));
    await settingsService.setCarpeaterInterval(minutes);
  }

  @override
  Future<void> setDeviceName(String? name) =>
      settingsService.setDeviceName(name);

  @override
  Future<void> setKeepScreenOn(bool value) async {
    updateState(() => setKeepScreenOnFlag(value));
    await settingsService.setKeepScreenOn(value);
    await ScreenWakeService.instance.setAlwaysOn(value);
  }

  @override
  Future<void> setBatterySaverEnabled(bool value) async {
    updateState(() => setBatterySaverFlag(value));
    await settingsService.setBatterySaverEnabled(value);
    locationService.setBatterySaverEnabled(value);
  }

  @override
  Future<void> setLockRotationNorth(bool value) async {
    updateState(() => setLockRotationFlag(value));
    if (value) resetMapRotation();
    await settingsService.setLockRotationNorth(value);
  }

  @override
  Future<void> setCurrentLocationMarkerStyle(
    CurrentLocationMarkerStyle style,
  ) async {
    updateState(() => setMarkerStyleFlag(style));
    if (style == CurrentLocationMarkerStyle.circle) {
      resetMapRotation();
    }
    syncCompassSubscription();
    await settingsService.setCurrentLocationMarkerStyle(style);
  }

  @override
  Future<void> calibrateCompass() => calibrateCompassFlow();

  @override
  Future<void> selectInterfaceTheme() =>
      _themeFlow.showInterfaceThemeSelector();

  @override
  Future<void> selectMapTheme() => _themeFlow.showMapThemeSelector();

  @override
  Future<void> selectLanguage() => _themeFlow.showLanguageSelector();

  @override
  Future<void> scanForRepeaters() => scanForRepeatersFlow();

  @override
  Future<void> refreshContacts() => refreshContactsFlow();

  @override
  Future<void> setColorMode(String mode) async {
    updateState(() => setColorModeFlag(mode));
    await settingsService.setColorMode(mode);
  }

  @override
  Future<void> setDistanceUnit(String unit) async {
    updateState(() => setDistanceUnitFlag(unit));
    await settingsService.setDistanceUnit(unit);
  }

  @override
  Future<void> setFuelUnit(String unit) async {
    updateState(() => setFuelUnitFlag(unit));
    await settingsService.setFuelUnit(unit);
  }

  @override
  Future<void> setColorBlindMode(String mode) async {
    updateState(() => setColorBlindModeFlag(mode));
    await settingsService.setColorBlindMode(mode);
  }

  @override
  Future<DrivingStatisticsValues> loadDrivingStatistics() async {
    return DrivingStatisticsValues(
      totalMeters: await settingsService.getTotalDistanceDriven(),
      vehicleMpg: await settingsService.getVehicleMpg(),
      gasPricePerGallon: await settingsService.getGasPrice(),
    );
  }

  @override
  Future<void> resetTotalDistance() =>
      settingsService.resetTotalDistanceDriven();

  @override
  Future<void> setVehicleMpg(double? mpg) => settingsService.setVehicleMpg(mpg);

  @override
  Future<void> setGasPrice(double price) => settingsService.setGasPrice(price);

  @override
  void openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AnalyticsScreen(
          samples: samples(),
          coveragePrecision: coveragePrecision(),
          currentPosition: currentPosition(),
        ),
      ),
    );
  }

  @override
  void openSessionHistory() => openSessionHistoryFlow();

  @override
  Future<void> downloadCommunityCoverage() => downloadCommunityCoverageFlow();

  @override
  Future<void> clearSessionFilter() async {
    updateState(() => setSessionMapView(const SessionMapView.all()));
    mapDataController.invalidate();
    await reloadSamples();
    if (!context.mounted) return;
    onShowSnackBar(AppLocalizations.of(context).settingsSessionFilterCleared);
  }

  @override
  Future<void> exportData() => exportDataFlow();

  @override
  Future<void> importData() => importDataFlow();

  @override
  Future<void> shareCoverageMap() => shareCoverageMapFlow();

  @override
  void showRepeaterFilterPicker() => showRepeaterFilterPickerFlow();

  @override
  Future<void> clearRepeaterFilter() async {
    await applyRepeaterFilter(null);
    if (!context.mounted) return;
    onShowSnackBar(AppLocalizations.of(context).settingsRepeaterFilterCleared);
  }

  @override
  Future<void> selectSourceFilter() async {
    final l10n = AppLocalizations.of(context);
    final sources = await databaseService.getDistinctSources();
    if (sources.isEmpty) {
      onShowSnackBar(l10n.settingsNoSourceTaggedData);
      return;
    }
    if (!context.mounted) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(AppLocalizations.of(dialogContext).settingsFilterBySource),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: Text(
              AppLocalizations.of(dialogContext).settingsShowAll,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          for (final source in sources)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, source),
              child: Text(source),
            ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (picked == null && activeSourceFilter() == null) return;
    updateState(() => setActiveSourceFilter(picked));
    mapDataController.invalidate();
    await reloadSamples();
    onShowSnackBar(
      picked == null
          ? l10n.settingsSourceFilterCleared
          : l10n.settingsShowingDataFrom(picked),
    );
  }

  @override
  Future<void> clearSourceFilter() async {
    updateState(() => setActiveSourceFilter(null));
    mapDataController.invalidate();
    await reloadSamples();
    if (!context.mounted) return;
    onShowSnackBar(AppLocalizations.of(context).settingsSourceFilterCleared);
  }

  @override
  Future<void> clearTileCache() async {
    final store = tileCacheStore();
    if (store == null) return;
    await store.clean();
    if (!context.mounted) return;
    onShowSnackBar(AppLocalizations.of(context).settingsTileCacheCleared);
  }

  @override
  Future<void> findCoverageGaps() => findCoverageGapsFlow();

  @override
  void enableDeleteMode() {
    updateState(() => setDeleteMode(true));
    onShowSnackBar(AppLocalizations.of(context).settingsDeleteModeOn);
  }

  @override
  Future<void> clearPlannedMarkers() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirmClear(
      title: l10n.settingsClearAllMarkers,
      confirm: l10n.settingsClearAllMarkersConfirm,
    );
    if (confirmed != true) return;
    for (final marker in plannedMarkers()) {
      await databaseService.deleteMarker(marker['id'] as int);
    }
    await loadMarkers();
    onShowSnackBar(l10n.settingsAllMarkersCleared);
  }

  @override
  Future<void> addPrivacyZone() => addPrivacyZoneAt(newZoneCenter());

  @override
  Future<void> clearPrivacyZones() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirmClear(
      title: l10n.settingsClearPrivacyZones,
      confirm: l10n.settingsClearPrivacyZonesConfirm,
    );
    if (confirmed != true) return;
    for (final zone in privacyZones()) {
      await databaseService.deletePrivacyZone(zone['id'] as int);
    }
    await loadPrivacyZones();
    onShowSnackBar(l10n.settingsPrivacyZonesCleared);
  }

  @override
  Future<void> clearMapData() => clearMapDataFlow();

  @override
  Future<void> downloadOfflineTiles() => downloadOfflineTilesFlow();

  @override
  Future<void> exportSettings() => exportSettingsFlow();

  @override
  Future<void> importSettings() => importSettingsFlow();

  @override
  Future<void> exportDatabase() => exportDatabaseFlow();

  @override
  Future<void> importDatabase() => importDatabaseFlow();

  @override
  Future<void> uploadSamples() => uploadSamplesFlow();

  @override
  Future<void> manageUploadSites() => manageUploadSitesFlow();

  @override
  void openDebugDiagnostics() => openDebugDiagnosticsFlow();

  @override
  Future<void> checkForUpdates() => checkForUpdatesFlow();

  @override
  Future<void> openGitHub() => openGitHubFlow();

  /// Shared "Cancel + destructive clear" confirmation used by the bulk
  /// marker and privacy-zone resets.
  Future<bool?> _confirmClear({
    required String title,
    required String confirm,
  }) {
    return showConfirmDialog(
      context,
      title: title,
      content: confirm,
      confirmLabel: AppLocalizations.of(context).settingsClear,
      destructive: true,
    );
  }
}
