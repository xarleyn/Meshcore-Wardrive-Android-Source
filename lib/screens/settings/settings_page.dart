part of '../map_screen.dart';

typedef _SettingsCategoryBuilder =
    List<Widget> Function(BuildContext context, StateSetter setPageState);

class _SettingsCategory {
  const _SettingsCategory({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String title;
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
            final categories = _buildSettingsCategories(context);

            return ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                _buildSettingsOverviewCard(context, categories.take(4)),
                const SizedBox(height: 16),
                _buildSettingsOverviewCard(context, categories.skip(4).take(4)),
                const SizedBox(height: 16),
                _buildSettingsOverviewCard(context, categories.skip(8).take(4)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_SettingsCategory> _buildSettingsCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return [
      _SettingsCategory(
        title: l10n.settingsSectionMapDisplay,
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
        title: l10n.settingsSectionLocation,
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
          onOpenLocationQuality: () => _openLocationQualitySettings(context),
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
        title: l10n.settingsSectionDiscovery,
        icon: Icons.radar_outlined,
        builder: (context, setPageState) =>
            _buildDiscoverySettings(context, setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionFeedback,
        icon: Icons.notifications_outlined,
        builder: (context, setPageState) => buildFeedbackSettings(
          context,
          values: FeedbackSettingsValues(
            soundEnabled: _soundEnabled,
            vibrationEnabled: _vibrationEnabled,
            deadZoneAlertsEnabled: _deadZoneAlertsEnabled,
            newRepeaterAlertsEnabled: _newRepeaterAlertsEnabled,
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
        ),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionCarpeater,
        icon: Icons.cell_tower,
        builder: (context, setPageState) => buildCarpeaterSettings(
          context,
          values: CarpeaterSettingsValues(
            enabled: _carpeaterEnabled,
            repeaterId: _carpeaterRepeaterId,
            password: _carpeaterPassword,
            interval: _carpeaterInterval,
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
        title: l10n.settingsSectionAppDevice,
        icon: Icons.tune,
        builder: (context, setPageState) =>
            _buildAppDeviceSettings(context, setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionOnlineMap,
        icon: Icons.cloud_outlined,
        builder: (context, _) => buildOnlineMapSettings(
          context,
          onUploadSamples: _uploadSamples,
          onManageUploadSites: _manageUploadSites,
        ),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionStatistics,
        icon: Icons.query_stats,
        builder: (context, setPageState) =>
            _buildStatisticsSettings(context, setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionDataManagement,
        icon: Icons.storage_outlined,
        builder: (context, setPageState) =>
            _buildDataManagementSettings(context, setPageState),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionBackup,
        icon: Icons.settings_backup_restore,
        builder: (context, _) => buildBackupSettings(
          context,
          onExportSettings: _exportSettings,
          onImportSettings: _importSettings,
        ),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionDiagnostics,
        icon: Icons.bug_report_outlined,
        builder: (context, _) => buildDiagnosticsSettings(
          context,
          samples: _samples,
          onOpenDebugDiagnostics: _openDebugDiagnostics,
        ),
      ),
      _SettingsCategory(
        title: l10n.settingsSectionAbout,
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

  Widget _buildSettingsOverviewCard(
    BuildContext context,
    Iterable<_SettingsCategory> categories,
  ) {
    return SettingsOverviewCard(
      children: [
        for (final category in categories)
          SettingsCategoryTile(
            title: category.title,
            icon: category.icon,
            onTap: () => _openSettingsCategory(context, category),
          ),
      ],
    );
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
