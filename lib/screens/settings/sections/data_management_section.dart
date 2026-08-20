part of '../../map_screen.dart';

extension _DataManagementSettingsSection on _MapScreenState {
  List<Widget> _buildDataManagementSettings(
    BuildContext context,
    StateSetter setModalState,
  ) {
    final l10n = AppLocalizations.of(context);
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalyticsScreen(
                samples: _samples,
                coveragePrecision: _coveragePrecision,
                currentPosition: _currentPosition,
              ),
            ),
          );
        },
      ),
      ListTile(
        title: Text(l10n.settingsAchievements),
        subtitle: Text(l10n.settingsAchievementsSubtitle),
        leading: const Icon(Icons.emoji_events),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AchievementsScreen()),
          );
        },
      ),
      ListTile(
        title: Text(l10n.settingsDeviceComparison),
        subtitle: Text(l10n.settingsDeviceComparisonSubtitle),
        leading: const Icon(Icons.devices),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DeviceComparisonScreen(),
            ),
          );
        },
      ),
      ListTile(
        title: Text(l10n.settingsDownloadCommunityCoverage),
        subtitle: Text(
          _communityCoverage != null
              ? l10n.settingsCommunityCoverageCached
              : l10n.settingsPullCoverageFromWeb,
        ),
        leading: const Icon(Icons.cloud_download),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          _downloadCommunityCoverage();
        },
      ),
      ListTile(
        title: Text(l10n.settingsSessionHistory),
        subtitle: Text(
          _sessionMapView.isFiltered
              ? l10n.settingsFilteringBySession
              : l10n.settingsViewPastSessions,
        ),
        leading: const Icon(Icons.history),
        trailing: _sessionMapView.isFiltered
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () {
                  _updateMapState(() {
                    _sessionMapView = const SessionMapView.all();
                  });
                  setModalState(() {});
                  _mapDataController.invalidate();
                  _loadSamples();
                  _showSnackBar(l10n.settingsSessionFilterCleared);
                },
                tooltip: l10n.settingsClearFilterTooltip,
              )
            : const Icon(Icons.arrow_forward),
        onTap: () {
          _openSessionHistory();
        },
      ),
      ListTile(
        title: Text(l10n.settingsExportData),
        subtitle: Text(l10n.settingsExportDataSubtitle),
        leading: const Icon(Icons.upload),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          _exportData();
        },
      ),
      ListTile(
        title: Text(l10n.settingsImportData),
        subtitle: Text(l10n.settingsImportDataSubtitle),
        leading: const Icon(Icons.download),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          _importData();
        },
      ),
      ListTile(
        title: Text(l10n.settingsShareCoverageMap),
        subtitle: Text(l10n.settingsShareCoverageMapSubtitle),
        leading: const Icon(Icons.share),
        onTap: () {
          _shareCoverageMap();
        },
      ),
      ListTile(
        title: Text(l10n.settingsFilterByRepeater),
        subtitle: Text(
          _includeOnlyRepeaters != null && _includeOnlyRepeaters!.isNotEmpty
              ? l10n.settingsFilteringRepeater(_includeOnlyRepeaters!)
              : l10n.settingsShowCoverageFromRepeater,
        ),
        leading: const Icon(Icons.filter_alt),
        trailing:
            _includeOnlyRepeaters != null && _includeOnlyRepeaters!.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () async {
                  _updateMapState(() {
                    _includeOnlyRepeaters = null;
                  });
                  await _settingsService.setIncludeOnlyRepeaters(null);
                  setModalState(() {});
                  _loadSamples();
                  _showSnackBar(l10n.settingsRepeaterFilterCleared);
                },
              )
            : const Icon(Icons.arrow_forward),
        onTap: () {
          _showRepeaterFilterPicker();
        },
      ),
      ListTile(
        title: Text(l10n.settingsFilterBySource),
        subtitle: Text(
          _activeSourceFilter != null
              ? l10n.settingsShowingSource(_activeSourceFilter!)
              : l10n.settingsFilterByDeviceOperator,
        ),
        leading: const Icon(Icons.people),
        trailing: _activeSourceFilter != null
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () async {
                  _updateMapState(() {
                    _activeSourceFilter = null;
                  });
                  setModalState(() {});
                  _mapDataController.invalidate();
                  _loadSamples();
                  _showSnackBar(l10n.settingsSourceFilterCleared);
                },
              )
            : const Icon(Icons.arrow_forward),
        onTap: () async {
          final sources = await _databaseService.getDistinctSources();
          if (sources.isEmpty) {
            _showSnackBar(l10n.settingsNoSourceTaggedData);
            return;
          }
          if (!context.mounted) return;
          final picked = await showDialog<String>(
            context: context,
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return SimpleDialog(
                title: Text(l10n.settingsFilterBySource),
                children: [
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text(
                      l10n.settingsShowAll,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  ...sources.map(
                    (s) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, s),
                      child: Text(s),
                    ),
                  ),
                ],
              );
            },
          );
          if (picked != null || _activeSourceFilter != null) {
            _updateMapState(() {
              _activeSourceFilter = picked;
            });
            setModalState(() {});
            _mapDataController.invalidate();
            _loadSamples();
            if (picked != null) {
              _showSnackBar(l10n.settingsShowingDataFrom(picked));
            } else {
              _showSnackBar(l10n.settingsSourceFilterCleared);
            }
          }
        },
      ),
      ListTile(
        title: Text(l10n.settingsFindCoverageGaps),
        subtitle: Text(l10n.settingsFindCoverageGapsSubtitle),
        leading: const Icon(Icons.location_searching),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          _closeSettingsPages(context);
          _findCoverageGaps();
        },
      ),
      ListTile(
        title: Text(l10n.settingsDeleteMode),
        subtitle: Text(l10n.settingsDeleteModeSubtitle),
        leading: const Icon(Icons.delete_sweep, color: Colors.orange),
        onTap: () {
          _closeSettingsPages(context);
          _updateMapState(() {
            _deleteMode = true;
          });
          _showSnackBar(l10n.settingsDeleteModeOn);
        },
      ),
      ListTile(
        title: Text(l10n.settingsPlannedRepeaters),
        subtitle: Text(
          l10n.settingsPlannedMarkersSubtitle(_plannedMarkers.length),
        ),
        leading: const Icon(Icons.add_location, color: Colors.amber),
        trailing: _plannedMarkers.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      final l10n = AppLocalizations.of(ctx);
                      return AlertDialog(
                        title: Text(l10n.settingsClearAllMarkers),
                        content: Text(l10n.settingsClearAllMarkersConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.settingsCancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              l10n.settingsClear,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirmed == true) {
                    for (final m in _plannedMarkers) {
                      await _databaseService.deleteMarker(m['id'] as int);
                    }
                    await _loadMarkers();
                    setModalState(() {});
                    _showSnackBar(l10n.settingsAllMarkersCleared);
                  }
                },
              )
            : null,
      ),
      ListTile(
        title: Text(l10n.settingsPrivacyZones),
        subtitle: Text(l10n.settingsPrivacyZonesSubtitle(_privacyZones.length)),
        leading: const Icon(Icons.shield, color: Colors.blueGrey),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () async {
          // Use current position or map center
          final center = _currentPosition ?? _mapController.camera.center;
          await _addPrivacyZone(center);
        },
      ),
      if (_privacyZones.isNotEmpty)
        ListTile(
          title: Text(l10n.settingsClearPrivacyZones),
          subtitle: Text(l10n.settingsRemoveAllZones(_privacyZones.length)),
          leading: const Icon(Icons.shield_outlined, color: Colors.red),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                final l10n = AppLocalizations.of(ctx);
                return AlertDialog(
                  title: Text(l10n.settingsClearPrivacyZones),
                  content: Text(l10n.settingsClearPrivacyZonesConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.settingsCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        l10n.settingsClear,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            );
            if (confirmed == true) {
              for (final z in _privacyZones) {
                await _databaseService.deletePrivacyZone(z['id'] as int);
              }
              await _loadPrivacyZones();
              _showSnackBar(l10n.settingsPrivacyZonesCleared);
            }
          },
        ),
      ListTile(
        title: Text(l10n.settingsClearMap),
        subtitle: Text(l10n.settingsClearMapSubtitle),
        leading: const Icon(Icons.delete, color: Colors.red),
        onTap: () {
          _clearData();
        },
      ),
      ListTile(
        title: Text(l10n.settingsDownloadOfflineTiles),
        subtitle: Text(l10n.settingsDownloadOfflineTilesSubtitle),
        leading: const Icon(Icons.download_for_offline),
        onTap: () {
          _showOfflineTileDownload();
        },
      ),
      ListTile(
        title: Text(l10n.settingsClearTileCache),
        subtitle: Text(l10n.settingsClearTileCacheSubtitle),
        leading: const Icon(Icons.cached, color: Colors.orange),
        onTap: () async {
          if (_tileCacheStore != null) {
            await _tileCacheStore!.clean();
            _showSnackBar(l10n.settingsTileCacheCleared);
          }
        },
      ),
    ];
  }
}
