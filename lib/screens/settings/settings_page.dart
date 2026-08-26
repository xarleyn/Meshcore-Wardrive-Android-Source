part of '../map_screen.dart';

typedef _SettingsCategoryBuilder = List<Widget> Function(
  BuildContext context,
  StateSetter setPageState,
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

void _closeSettingsPages(BuildContext context) {
  final navigator = Navigator.of(context);
  navigator.pop();
  navigator.pop();
}

extension _SettingsPageNavigation on _MapScreenState {
  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen(
          version: appVersion,
          contentBuilder: (context, setPageState, scrollController) {
            final groups = _buildSettingsOverviewGroups(context);

            return ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                for (final group in groups)
                  SettingsOverviewGroup(
                    title: group.title,
                    children: [
                      for (final category in group.categories)
                        SettingsCategoryTile(
                          title: category.title,
                          subtitle: category.subtitle,
                          icon: category.icon,
                          onTap: () => _openSettingsCategory(context, category),
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

  List<_SettingsOverviewGroup> _buildSettingsOverviewGroups(
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context);
    final categories = _buildSettingsCategories(context);

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

  List<_SettingsCategory> _buildSettingsCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return [
      _SettingsCategory(
        group: _SettingsOverviewGroupId.map,
        title: l10n.settingsSectionMapDisplay,
        subtitle: l10n.settingsSectionMapDisplayDescription,
        icon: Icons.map_outlined,
        builder: (context, setPageState) => buildMapDisplaySettings(
          context,
          values: MapDisplaySettingsValues(
            showCoverage: _showCoverage,
            mapLodEnabled: _mapLodEnabled,
            showSamples: _showSamples,
            showEdges: _showEdges,
            showRepeaters: _showRepeaters,
            showGpsSamples: _showGpsSamples,
            showSuccessfulOnly: _showSuccessfulOnly,
            optimisticDisplay: _optimisticDisplay,
            showRouteTrail: _showRouteTrail,
            communityCoverageAvailable: _communityCoverage != null,
            showCommunityCoverage: _showCommunityCoverage,
            showHeatmap: _showHeatmap,
            showPredictionRings: _showPredictionRings,
          ),
          onChanged: (setting, value) =>
              _setMapDisplaySetting(setting, value, setPageState),
          onClearCommunityCoverage: () => _clearCommunityCoverage(setPageState),
        ),
      ),
      _SettingsCategory(
        group: _SettingsOverviewGroupId.map,
        title: l10n.settingsSectionLocation,
        subtitle: l10n.settingsSectionLocationDescription,
        icon: Icons.my_location_outlined,
        builder: (context, setPageState) => buildLocationSettings(
          context,
          values: LocationSettingsValues(
            beaconDbWifiPositioning: _beaconDbWifiPositioning,
            showRadioPosition: _showRadioPosition,
            showDucting: _showDucting,
          ),
          onBeaconDbChanged: (value) async {
            _updateMapState(() => _beaconDbWifiPositioning = value);
            setPageState(() {});
            await _settingsService.setBeaconDbWifiPositioning(value);
            _locationService.setWifiPositioningEnabled(value);
            if (value) {
              _showSnackBar(l10n.settingsBeaconDbEnabledSnack);
              await _requestWifiScanThrottlingDisabled();
            }
          },
          onOpenLocationQuality: () => _showLocationQualitySettings(context),
          onRadioPositionChanged: (value) async {
            _updateMapState(() => _showRadioPosition = value);
            setPageState(() {});
            await _settingsService.setShowRadioPosition(value);
          },
          onDuctingChanged: (value) async {
            _updateMapState(() => _showDucting = value);
            setPageState(() {});
            await _settingsService.setShowDucting(value);
            _locationService.setDuctingEnabled(value);
            if (value) {
              final risk = await _locationService.ductingService
                  .getLatestRisk();
              _updateMapState(() => _currentDuctingRisk = risk);
            }
          },
        ),
      ),
      _SettingsCategory(
        group: _SettingsOverviewGroupId.sampling,
        title: l10n.settingsSectionDiscovery,
        subtitle: l10n.settingsSectionDiscoveryDescription,
        icon: Icons.radar_outlined,
        builder: (context, setPageState) => buildDiscoverySettings(
          context,
          values: DiscoverySettingsValues(
            timeoutSeconds: _discoveryTimeoutSeconds,
            thoroughResponseCollection: _thoroughResponseCollection,
            ignoredRepeaterPrefix: _ignoredRepeaterPrefix,
            includeOnlyRepeaters: _includeOnlyRepeaters,
            filterEdgesByWhitelist: _filterEdgesByWhitelist,
            pingMode: _pingMode,
            pingTimeInterval: _pingTimeInterval,
            pingIntervalDescription: pingIntervalDescription(
              context,
              _pingIntervalMeters,
            ),
            coverageResolutionDescription: coverageResolutionDescription(
              context,
              _coveragePrecision,
            ),
          ),
          onTimeoutChanged: (value) async {
            _updateMapState(() => _discoveryTimeoutSeconds = value);
            setPageState(() {});
            await _settingsService.setDiscoveryTimeout(value);
          },
          onThoroughChanged: (value) async {
            _updateMapState(() => _thoroughResponseCollection = value);
            setPageState(() {});
            await _settingsService.setThoroughResponseCollection(value);
          },
          onEditIgnoredRepeaters: () => _editIgnoredRepeaters(context),
          onEditIncludedRepeaters: () => _editIncludedRepeaters(context),
          onFilterEdgesChanged: (value) async {
            _updateMapState(() => _filterEdgesByWhitelist = value);
            setPageState(() {});
            await _settingsService.setFilterEdgesByWhitelist(value);
          },
          onPingModeChanged: (value) async {
            _updateMapState(() => _pingMode = value);
            setPageState(() {});
            await _settingsService.setPingMode(value);
            _locationService.setPingMode(value);
          },
          onEditPingInterval: () => _editPingInterval(context),
          onPingTimeIntervalChanged: (value) async {
            _updateMapState(() => _pingTimeInterval = value);
            setPageState(() {});
            await _settingsService.setPingTimeInterval(value);
            _locationService.setPingTimeInterval(value);
          },
          onEditCoverageResolution: () => _editCoverageResolution(context),
        ),
      ),
      _SettingsCategory(
        group: _SettingsOverviewGroupId.sampling,
        title: l10n.settingsSectionFeedback,
        subtitle: l10n.settingsSectionFeedbackDescription,
        icon: Icons.notifications_outlined,
        builder: (context, setPageState) => buildFeedbackSettings(
          context,
          values: FeedbackSettingsValues(
            soundEnabled: _soundEnabled,
            vibrationEnabled: _vibrationEnabled,
            deadZoneAlertsEnabled: _deadZoneAlertsEnabled,
            newRepeaterAlertsEnabled: _newRepeaterAlertsEnabled,
            linkLossAlertsEnabled: _linkLossAlertsEnabled,
          ),
          onSoundChanged: (value) async {
            _updateMapState(() => _soundEnabled = value);
            setPageState(() {});
            await _settingsService.setSoundEnabled(value);
            SoundService().setEnabled(value);
          },
          onVibrationChanged: (value) async {
            _updateMapState(() => _vibrationEnabled = value);
            setPageState(() {});
            await _settingsService.setVibrationEnabled(value);
            SoundService().setVibrationEnabled(value);
          },
          onDeadZoneAlertsChanged: (value) async {
            _updateMapState(() => _deadZoneAlertsEnabled = value);
            setPageState(() {});
            await _settingsService.setDeadZoneAlertsEnabled(value);
          },
          onNewRepeaterAlertsChanged: (value) async {
            _updateMapState(() => _newRepeaterAlertsEnabled = value);
            setPageState(() {});
            await _settingsService.setNewRepeaterAlertsEnabled(value);
            _locationService.loraCompanion.setNewRepeaterAlertsEnabled(value);
          },
          onLinkLossAlertsChanged: (value) async {
            _updateMapState(() => _linkLossAlertsEnabled = value);
            setPageState(() {});
            await _settingsService.setLinkLossAlertsEnabled(value);
            _locationService.setLinkLossAlertsEnabled(value);
          },
        ),
      ),
      _SettingsCategory(
        group: _SettingsOverviewGroupId.sampling,
        title: l10n.settingsSectionCarpeater,
        subtitle: l10n.settingsSectionCarpeaterDescription,
        icon: Icons.cell_tower,
        builder: (context, setPageState) => buildCarpeaterSettings(
          context,
          values: CarpeaterSettingsValues(
            enabled: _carpeaterEnabled,
            repeaterId: _carpeaterRepeaterId,
            password: _carpeaterPassword,
            interval: _carpeaterInterval,
            foundRepeaters:
                _locationService.loraCompanion.knownRepeaterContacts,
          ),
          onEnabledChanged: (value) async {
            _updateMapState(() => _carpeaterEnabled = value);
            setPageState(() {});
            await _settingsService.setCarpeaterEnabled(value);
            _locationService.setCarpeaterMode(value);
            _updateMapState(() {
              _autoPingEnabled = _locationService.isAutoPingEnabled;
            });
          },
          onRepeaterIdChanged: (value) async {
            _updateMapState(() => _carpeaterRepeaterId = value);
            setPageState(() {});
            await _settingsService.setCarpeaterRepeaterId(value);
          },
          onPasswordChanged: (value) async {
            _updateMapState(() => _carpeaterPassword = value);
            setPageState(() {});
            await _settingsService.setCarpeaterPassword(value);
          },
          onIntervalChanged: (value) async {
            _updateMapState(() => _carpeaterInterval = value);
            setPageState(() {});
            await _settingsService.setCarpeaterInterval(value);
          },
        ),
      ),
      _SettingsCategory(
        group: _SettingsOverviewGroupId.app,
        title: l10n.settingsSectionAppDevice,
        subtitle: l10n.settingsSectionAppDeviceDescription,
        icon: Icons.tune,
        builder: (context, setPageState) => buildAppDeviceSettings(
          context,
          values: AppDeviceSettingsValues(
            deviceName: _settingsService.getDeviceName(),
            keepScreenOn: _keepScreenOn,
            batterySaverEnabled: _batterySaverEnabled,
            lockRotationNorth: _lockRotationNorth,
            currentLocationMarkerStyle: _currentLocationMarkerStyle,
            interfaceThemeDescription: _getInterfaceThemeModeText(),
            mapThemeDescription: _getMapThemeModeText(),
            localePreferenceDescription: _getAppLocalePreferenceText(),
            loraConnected: _loraConnected,
            repeaterCount: _repeaters.length,
            colorMode: _colorMode,
            distanceUnit: _distanceUnit,
            fuelUnit: _fuelUnit,
            colorBlindMode: _colorBlindMode,
          ),
          onDeviceNameChanged: (value) async {
            await _settingsService.setDeviceName(value);
            setPageState(() {});
          },
          onKeepScreenOnChanged: (value) async {
            _updateMapState(() => _keepScreenOn = value);
            setPageState(() {});
            await _settingsService.setKeepScreenOn(value);
            await ScreenWakeService.instance.setAlwaysOn(value);
          },
          onBatterySaverChanged: (value) async {
            _updateMapState(() => _batterySaverEnabled = value);
            setPageState(() {});
            await _settingsService.setBatterySaverEnabled(value);
            _locationService.setBatterySaverEnabled(value);
          },
          onLockRotationNorthChanged: (value) async {
            _updateMapState(() {
              _lockRotationNorth = value;
              if (value) _followHeading = false;
            });
            if (value) _mapController.rotate(0);
            setPageState(() {});
            await _settingsService.setLockRotationNorth(value);
          },
          onCurrentLocationMarkerStyleChanged: (value) async {
            _updateMapState(() {
              _currentLocationMarkerStyle = value;
              if (value == CurrentLocationMarkerStyle.circle) {
                _followHeading = false;
              }
            });
            if (value == CurrentLocationMarkerStyle.circle) {
              _mapController.rotate(0);
            }
            setPageState(() {});
            _syncCompassSubscription();
            await _settingsService.setCurrentLocationMarkerStyle(value);
          },
          onCalibrateCompass: () =>
              _openCompassCalibration(snoozeOnDismiss: false),
          onSelectInterfaceTheme: _showInterfaceThemeSelector,
          onSelectMapTheme: _showMapThemeSelector,
          onSelectLanguage: _showLanguageSelector,
          onScanForRepeaters: _scanForRepeaters,
          onRefreshContacts: _refreshContacts,
          onColorModeChanged: (value) async {
            _updateMapState(() => _colorMode = value);
            setPageState(() {});
            await _settingsService.setColorMode(value);
          },
          onDistanceUnitChanged: (value) async {
            _updateMapState(() {
              _distanceUnit = value;
              _totalDistance = value == 'miles'
                  ? _locationService.totalDistanceMiles
                  : _locationService.totalDistanceKm;
            });
            setPageState(() {});
            await _settingsService.setDistanceUnit(value);
          },
          onFuelUnitChanged: (value) async {
            _updateMapState(() => _fuelUnit = value);
            setPageState(() {});
            await _settingsService.setFuelUnit(value);
          },
          onColorBlindModeChanged: (value) async {
            _updateMapState(() => _colorBlindMode = value);
            setPageState(() {});
            await _settingsService.setColorBlindMode(value);
          },
        ),
      ),
      _SettingsCategory(
        group: _SettingsOverviewGroupId.map,
        title: l10n.settingsSectionOnlineMap,
        subtitle: l10n.settingsSectionOnlineMapDescription,
        icon: Icons.cloud_outlined,
        builder: (context, _) => buildOnlineMapSettings(
          context,
          onUploadSamples: _uploadSamples,
          onManageUploadSites: _manageUploadSites,
        ),
      ),
      _SettingsCategory(
        group: _SettingsOverviewGroupId.app,
        title: l10n.settingsSectionStatistics,
        subtitle: l10n.settingsSectionStatisticsDescription,
        icon: Icons.query_stats,
        builder: (context, setPageState) => buildStatisticsSettings(
          context,
          values: _loadDrivingStatistics(),
          sessionMeters: _isTracking ? _locationService.totalDistanceMeters : 0,
          distanceUnit: _distanceUnit,
          fuelUnit: _fuelUnit,
          onResetDistance: () async {
            await _settingsService.resetTotalDistanceDriven();
            setPageState(() {});
          },
          onVehicleMpgChanged: (value) async {
            await _settingsService.setVehicleMpg(value);
            setPageState(() {});
          },
          onGasPriceChanged: (value) async {
            await _settingsService.setGasPrice(value);
            setPageState(() {});
          },
        ),
      ),
      _SettingsCategory(
        group: _SettingsOverviewGroupId.data,
        title: l10n.settingsSectionDataManagement,
        subtitle: l10n.settingsSectionDataManagementDescription,
        icon: Icons.storage_outlined,
        builder: (context, setPageState) => buildDataManagementSettings(
          context,
          values: DataManagementSettingsValues(
            communityCoverageAvailable: _communityCoverage != null,
            sessionFiltered: _sessionMapView.isFiltered,
            includeOnlyRepeaters: _includeOnlyRepeaters,
            activeSourceFilter: _activeSourceFilter,
            plannedMarkerCount: _plannedMarkers.length,
            privacyZoneCount: _privacyZones.length,
          ),
          onOpenAnalytics: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => AnalyticsScreen(
                samples: _samples,
                coveragePrecision: _coveragePrecision,
                currentPosition: _currentPosition,
              ),
            ),
          ),
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
          onDownloadCommunityCoverage: _downloadCommunityCoverage,
          onOpenSessionHistory: _openSessionHistory,
          onClearSessionFilter: () {
            _updateMapState(() {
              _sessionMapView = const SessionMapView.all();
            });
            setPageState(() {});
            _mapDataController.invalidate();
            _loadSamples();
            _showSnackBar(l10n.settingsSessionFilterCleared);
          },
          onExportData: _exportData,
          onImportData: _importData,
          onShareCoverageMap: _shareCoverageMap,
          onOpenRepeaterFilter: _showRepeaterFilterPicker,
          onClearRepeaterFilter: () async {
            _updateMapState(() => _includeOnlyRepeaters = null);
            await _settingsService.setIncludeOnlyRepeaters(null);
            setPageState(() {});
            _loadSamples();
            _showSnackBar(l10n.settingsRepeaterFilterCleared);
          },
          onOpenSourceFilter: () => _selectSourceFilter(context, setPageState),
          onClearSourceFilter: () {
            _updateMapState(() => _activeSourceFilter = null);
            setPageState(() {});
            _mapDataController.invalidate();
            _loadSamples();
            _showSnackBar(l10n.settingsSourceFilterCleared);
          },
          onFindCoverageGaps: () {
            _closeSettingsPages(context);
            _findCoverageGaps();
          },
          onEnableDeleteMode: () {
            _closeSettingsPages(context);
            _updateMapState(() => _deleteMode = true);
            _showSnackBar(l10n.settingsDeleteModeOn);
          },
          onClearPlannedMarkers: () =>
              _clearPlannedMarkers(context, setPageState),
          onAddPrivacyZone: () async {
            final center = _currentPosition ?? _mapController.camera.center;
            await _addPrivacyZone(center);
            setPageState(() {});
          },
          onClearPrivacyZones: () => _clearPrivacyZones(context, setPageState),
          onClearMap: _clearData,
          onDownloadOfflineTiles: _showOfflineTileDownload,
          onClearTileCache: () async {
            final store = _tileCacheStore;
            if (store == null) return;
            await store.clean();
            _showSnackBar(l10n.settingsTileCacheCleared);
          },
        ),
      ),
      _SettingsCategory(
        group: _SettingsOverviewGroupId.data,
        title: l10n.settingsSectionBackup,
        subtitle: l10n.settingsSectionBackupDescription,
        icon: Icons.settings_backup_restore,
        builder: (context, _) => buildBackupSettings(
          context,
          onExportSettings: _exportSettings,
          onImportSettings: _importSettings,
        ),
      ),
      _SettingsCategory(
        group: _SettingsOverviewGroupId.system,
        title: l10n.settingsSectionDiagnostics,
        subtitle: l10n.settingsSectionDiagnosticsDescription,
        icon: Icons.bug_report_outlined,
        builder: (context, _) => buildDiagnosticsSettings(
          context,
          samples: _samples,
          onOpenDebugDiagnostics: _openDebugDiagnostics,
        ),
      ),
      _SettingsCategory(
        group: _SettingsOverviewGroupId.system,
        title: l10n.settingsSectionAbout,
        subtitle: l10n.settingsSectionAboutDescription,
        icon: Icons.info_outline,
        builder: (context, _) => buildAboutSettings(
          context,
          version: appVersion,
          onCheckForUpdates: _checkForUpdates,
          onOpenGitHub: _openGitHub,
        ),
      ),
    ];
  }

  Future<void> _editPingInterval(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final interval = await showPingIntervalDialog(context);
    if (interval == null || !mounted) return;
    _updateMapState(() => _pingIntervalMeters = interval);
    _locationService.setPingInterval(interval);
    await _settingsService.setPingInterval(interval);
    if (!mounted) return;
    _showSnackBar(
      l10n.settingsPingIntervalSet(
        pingIntervalDescription(this.context, interval),
      ),
    );
  }

  Future<void> _editCoverageResolution(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final precision = await showCoverageResolutionDialog(context);
    if (precision == null || !mounted) return;
    _updateMapState(() => _coveragePrecision = precision);
    await _settingsService.setCoveragePrecision(precision);
    _mapDataController.invalidate();
    await _loadSamples();
    if (!mounted) return;
    _showSnackBar(
      l10n.settingsCoverageResolutionSet(
        coverageResolutionDescription(this.context, precision),
      ),
    );
  }

  Future<void> _editIgnoredRepeaters(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showIgnoredRepeaterDialog(
      context,
      currentValue: _ignoredRepeaterPrefix,
    );
    if (result == null || !mounted) return;
    _updateMapState(() => _ignoredRepeaterPrefix = result.value);
    _locationService.loraCompanion.setIgnoredRepeaterPrefix(result.value);
    await _settingsService.setIgnoredRepeaterPrefix(result.value);
    if (mounted) _showSnackBar(l10n.settingsRepeaterPrefixUpdated);
  }

  Future<void> _editIncludedRepeaters(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showIncludedRepeaterDialog(
      context,
      currentValue: _includeOnlyRepeaters,
    );
    if (result == null || !mounted) return;
    _updateMapState(() => _includeOnlyRepeaters = result.value);
    await _settingsService.setIncludeOnlyRepeaters(result.value);
    if (mounted) _showSnackBar(l10n.settingsRepeaterWhitelistUpdated);
  }

  Future<void> _setMapDisplaySetting(
    MapDisplaySetting setting,
    bool value,
    StateSetter setPageState,
  ) async {
    switch (setting) {
      case MapDisplaySetting.coverage:
        _updateMapState(() => _showCoverage = value);
      case MapDisplaySetting.mapLod:
        _updateMapState(() => _mapLodEnabled = value);
      case MapDisplaySetting.samples:
        _updateMapState(() => _showSamples = value);
      case MapDisplaySetting.edges:
        _updateMapState(() => _showEdges = value);
      case MapDisplaySetting.repeaters:
        _updateMapState(() => _showRepeaters = value);
      case MapDisplaySetting.gpsSamples:
        _updateMapState(() => _showGpsSamples = value);
      case MapDisplaySetting.successfulOnly:
        _updateMapState(() => _showSuccessfulOnly = value);
      case MapDisplaySetting.optimisticDisplay:
        _updateMapState(() => _optimisticDisplay = value);
      case MapDisplaySetting.routeTrail:
        _updateMapState(() => _showRouteTrail = value);
      case MapDisplaySetting.communityCoverage:
        _updateMapState(() => _showCommunityCoverage = value);
      case MapDisplaySetting.heatmap:
        _updateMapState(() => _showHeatmap = value);
      case MapDisplaySetting.predictionRings:
        _updateMapState(() => _showPredictionRings = value);
    }
    setPageState(() {});

    switch (setting) {
      case MapDisplaySetting.coverage:
        await _settingsService.setShowCoverage(value);
      case MapDisplaySetting.mapLod:
        await _settingsService.setMapLodEnabled(value);
      case MapDisplaySetting.samples:
        await _settingsService.setShowSamples(value);
      case MapDisplaySetting.edges:
        await _settingsService.setShowEdges(value);
      case MapDisplaySetting.repeaters:
        await _settingsService.setShowRepeaters(value);
      case MapDisplaySetting.gpsSamples:
        await _settingsService.setShowGpsSamples(value);
      case MapDisplaySetting.successfulOnly:
        await _settingsService.setShowSuccessfulOnly(value);
      case MapDisplaySetting.optimisticDisplay:
        await _settingsService.setOptimisticDisplay(value);
        // Optimism changes the aggregated cell colors, so rebuild them now.
        _mapDataController.invalidate();
        await _loadSamples();
      case MapDisplaySetting.routeTrail:
        await _settingsService.setShowRouteTrail(value);
      case MapDisplaySetting.communityCoverage:
        break;
      case MapDisplaySetting.heatmap:
        await _settingsService.setShowHeatmap(value);
        _heatmapRebuildStream.add(null);
      case MapDisplaySetting.predictionRings:
        await _settingsService.setShowPredictionRings(value);
    }
  }

  Future<void> _clearCommunityCoverage(StateSetter setPageState) async {
    await _uploadService.clearCachedCoverage();
    _updateMapState(() {
      _communityCoverage = null;
      _showCommunityCoverage = false;
    });
    setPageState(() {});
    if (!mounted) return;
    _showSnackBar(
      AppLocalizations.of(context).settingsCommunityCoverageCleared,
    );
  }

  Future<DrivingStatisticsValues> _loadDrivingStatistics() async {
    return DrivingStatisticsValues(
      totalMeters: await _settingsService.getTotalDistanceDriven(),
      vehicleMpg: await _settingsService.getVehicleMpg(),
      gasPricePerGallon: await _settingsService.getGasPrice(),
    );
  }

  Future<void> _showLocationQualitySettings(BuildContext context) async {
    await _loadImpossibleZones();
    if (!context.mounted) return;
    await showLocationQualitySettings(
      context,
      settings: () => _locationQualitySettings,
      zones: () => _impossibleZones,
      newZoneCenter: () => _currentPosition ?? _mapController.camera.center,
      onSettingsChanged: (settings) async {
        await _settingsService.setLocationQualitySettings(settings);
        if (!mounted) return;
        _updateMapState(() => _locationQualitySettings = settings);
        _locationService.setLocationQualitySettings(settings);
      },
      onResetSettings: () async {
        const settings = LocationQualitySettings();
        await _settingsService.setLocationQualitySettings(settings);
        if (!mounted) return;
        _updateMapState(() => _locationQualitySettings = settings);
        _locationService.setLocationQualitySettings(settings);
        _showSnackBar(
          AppLocalizations.of(this.context).settingsLocationQualityResetSnack,
        );
      },
      onAddZone: (draft) async {
        await _databaseService.addImpossibleZone(
          draft.center.latitude,
          draft.center.longitude,
          draft.radiusMeters,
          draft.label,
        );
        await _loadImpossibleZones();
        if (!mounted) return;
        _showSnackBar(
          AppLocalizations.of(this.context).settingsImpossibleZoneAdded,
        );
      },
      onDeleteZone: (id) async {
        await _databaseService.deleteImpossibleZone(id);
        await _loadImpossibleZones();
      },
      onClearZones: () async {
        for (final zone in _impossibleZones) {
          final id = zone.id;
          if (id != null) await _databaseService.deleteImpossibleZone(id);
        }
        await _loadImpossibleZones();
      },
    );
  }

  Future<void> _selectSourceFilter(
    BuildContext context,
    StateSetter setPageState,
  ) async {
    final l10n = AppLocalizations.of(context);
    final sources = await _databaseService.getDistinctSources();
    if (sources.isEmpty) {
      _showSnackBar(l10n.settingsNoSourceTaggedData);
      return;
    }
    if (!context.mounted) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context).settingsFilterBySource),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              AppLocalizations.of(context).settingsShowAll,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          for (final source in sources)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, source),
              child: Text(source),
            ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (picked == null && _activeSourceFilter == null) return;
    _updateMapState(() => _activeSourceFilter = picked);
    setPageState(() {});
    _mapDataController.invalidate();
    _loadSamples();
    _showSnackBar(
      picked == null
          ? l10n.settingsSourceFilterCleared
          : l10n.settingsShowingDataFrom(picked),
    );
  }

  Future<void> _clearPlannedMarkers(
    BuildContext context,
    StateSetter setPageState,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).settingsClearAllMarkers),
        content: Text(
          AppLocalizations.of(context).settingsClearAllMarkersConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context).settingsClear,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final marker in _plannedMarkers) {
      await _databaseService.deleteMarker(marker['id'] as int);
    }
    await _loadMarkers();
    if (!context.mounted) return;
    setPageState(() {});
    _showSnackBar(l10n.settingsAllMarkersCleared);
  }

  Future<void> _clearPrivacyZones(
    BuildContext context,
    StateSetter setPageState,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).settingsClearPrivacyZones),
        content: Text(
          AppLocalizations.of(context).settingsClearPrivacyZonesConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context).settingsClear,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (final zone in _privacyZones) {
      await _databaseService.deletePrivacyZone(zone['id'] as int);
    }
    await _loadPrivacyZones();
    if (!context.mounted) return;
    setPageState(() {});
    _showSnackBar(l10n.settingsPrivacyZonesCleared);
  }

  void _openSettingsCategory(BuildContext context, _SettingsCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen.category(
          title: category.title,
          contentBuilder: (context, setPageState, scrollController) {
            final children = category.builder(context, setPageState).toList();
            if (children.isNotEmpty &&
                children.first is SettingsSectionHeader) {
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
}
