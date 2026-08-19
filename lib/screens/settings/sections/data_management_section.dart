part of '../../map_screen.dart';

extension _DataManagementSettingsSection on _MapScreenState {
  List<Widget> _buildDataManagementSettings(
    BuildContext context,
    StateSetter setModalState,
  ) => [
    const SettingsSectionHeader(
      title: 'Data management',
      icon: Icons.storage_outlined,
    ),
    ListTile(
      title: const Text('Analytics'),
      subtitle: const Text('Time, goals, comparison & repeater stats'),
      leading: const Icon(Icons.analytics),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
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
      title: const Text('Achievements'),
      subtitle: const Text('Wardrive milestone badges'),
      leading: const Icon(Icons.emoji_events),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AchievementsScreen()),
        );
      },
    ),
    ListTile(
      title: const Text('Device Comparison'),
      subtitle: const Text('Compare LoRa companion performance'),
      leading: const Icon(Icons.devices),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DeviceComparisonScreen(),
          ),
        );
      },
    ),
    ListTile(
      title: const Text('Download Community Coverage'),
      subtitle: Text(
        _communityCoverage != null
            ? 'Cached — toggle in map layers'
            : 'Pull coverage data from web map',
      ),
      leading: const Icon(Icons.cloud_download),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        _downloadCommunityCoverage();
      },
    ),
    ListTile(
      title: const Text('Session History'),
      subtitle: Text(
        _sessionMapView.isFiltered
            ? 'Filtering by session'
            : 'View past wardrive sessions',
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
                _lastAggregatedSampleCount = -1; // Force reaggregation
                _loadSamples();
                _showSnackBar('Session filter cleared');
              },
              tooltip: 'Clear filter',
            )
          : const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        _openSessionHistory();
      },
    ),
    ListTile(
      title: const Text('Export Data'),
      subtitle: const Text('JSON, CSV, GPX, or KML'),
      leading: const Icon(Icons.upload),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        _exportData();
      },
    ),
    ListTile(
      title: const Text('Import Data'),
      subtitle: const Text('Load samples from file'),
      leading: const Icon(Icons.download),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        _importData();
      },
    ),
    ListTile(
      title: const Text('Share Coverage Map'),
      subtitle: const Text('Screenshot + share in one tap'),
      leading: const Icon(Icons.share),
      onTap: () {
        Navigator.pop(context);
        _shareCoverageMap();
      },
    ),
    ListTile(
      title: const Text('Filter by Repeater'),
      subtitle: Text(
        _includeOnlyRepeaters != null && _includeOnlyRepeaters!.isNotEmpty
            ? 'Filtering: $_includeOnlyRepeaters'
            : 'Show coverage from a specific repeater',
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
                _showSnackBar('Repeater filter cleared');
              },
            )
          : const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        _showRepeaterFilterPicker();
      },
    ),
    ListTile(
      title: const Text('Filter by Source'),
      subtitle: Text(
        _activeSourceFilter != null
            ? 'Showing: $_activeSourceFilter'
            : 'Filter by device/operator',
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
                _lastAggregatedSampleCount = -1;
                _loadSamples();
                _showSnackBar('Source filter cleared');
              },
            )
          : const Icon(Icons.arrow_forward),
      onTap: () async {
        final sources = await DatabaseService().getDistinctSources();
        if (sources.isEmpty) {
          _showSnackBar('No source-tagged data yet');
          return;
        }
        if (!context.mounted) return;
        final picked = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Filter by Source'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, null),
                child: const Text(
                  'Show All',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              ...sources.map(
                (s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, s),
                  child: Text(s),
                ),
              ),
            ],
          ),
        );
        if (picked != null || _activeSourceFilter != null) {
          _updateMapState(() {
            _activeSourceFilter = picked;
          });
          setModalState(() {});
          _lastAggregatedSampleCount = -1;
          _loadSamples();
          if (picked != null) {
            _showSnackBar('Showing data from: $picked');
          } else {
            _showSnackBar('Source filter cleared');
          }
        }
      },
    ),
    ListTile(
      title: const Text('Find Coverage Gaps'),
      subtitle: const Text('Locate areas with poor signal'),
      leading: const Icon(Icons.location_searching),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        _findCoverageGaps();
      },
    ),
    ListTile(
      title: const Text('Delete Mode'),
      subtitle: const Text('Tap to delete individual samples or cells'),
      leading: const Icon(Icons.delete_sweep, color: Colors.orange),
      onTap: () {
        Navigator.pop(context);
        _updateMapState(() {
          _deleteMode = true;
        });
        _showSnackBar(
          'Delete mode ON — tap a coverage square or sample to delete',
        );
      },
    ),
    ListTile(
      title: const Text('Planned Repeaters'),
      subtitle: Text(
        '${_plannedMarkers.length} marker(s) — long-press map to add',
      ),
      leading: const Icon(Icons.add_location, color: Colors.amber),
      trailing: _plannedMarkers.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.red, size: 20),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Markers'),
                    content: const Text('Remove all planned repeater markers?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  for (final m in _plannedMarkers) {
                    await DatabaseService().deleteMarker(m['id'] as int);
                  }
                  await _loadMarkers();
                  setModalState(() {});
                  _showSnackBar('All markers cleared');
                }
              },
            )
          : null,
    ),
    ListTile(
      title: const Text('Privacy Zones'),
      subtitle: Text(
        '${_privacyZones.length} zone(s) — excludes data from uploads',
      ),
      leading: const Icon(Icons.shield, color: Colors.blueGrey),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () async {
        Navigator.pop(context);
        // Use current position or map center
        final center = _currentPosition ?? _mapController.camera.center;
        await _addPrivacyZone(center);
      },
    ),
    if (_privacyZones.isNotEmpty)
      ListTile(
        title: const Text('Clear Privacy Zones'),
        subtitle: Text('Remove all ${_privacyZones.length} zone(s)'),
        leading: const Icon(Icons.shield_outlined, color: Colors.red),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Clear Privacy Zones'),
              content: const Text(
                'Remove all privacy zones? Data will no longer be filtered from uploads.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            for (final z in _privacyZones) {
              await DatabaseService().deletePrivacyZone(z['id'] as int);
            }
            await _loadPrivacyZones();
            _showSnackBar('Privacy zones cleared');
          }
        },
      ),
    ListTile(
      title: const Text('Clear Map'),
      subtitle: const Text('Delete all samples and coverage'),
      leading: const Icon(Icons.delete, color: Colors.red),
      onTap: () {
        Navigator.pop(context);
        _clearData();
      },
    ),
    ListTile(
      title: const Text('Download Offline Tiles'),
      subtitle: const Text('Cache map tiles for current view'),
      leading: const Icon(Icons.download_for_offline),
      onTap: () {
        Navigator.pop(context);
        _showOfflineTileDownload();
      },
    ),
    ListTile(
      title: const Text('Clear Tile Cache'),
      subtitle: const Text('Remove cached offline map tiles'),
      leading: const Icon(Icons.cached, color: Colors.orange),
      onTap: () async {
        if (_tileCacheStore != null) {
          await _tileCacheStore!.clean();
          _showSnackBar('Tile cache cleared');
        }
      },
    ),
  ];
}
