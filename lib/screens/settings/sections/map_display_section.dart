part of '../../map_screen.dart';

extension _MapDisplaySettingsSection on _MapScreenState {
  List<Widget> _buildMapDisplaySettings(StateSetter setModalState) => [
    const SettingsSectionHeader(title: 'Map display', icon: Icons.map_outlined),
    SwitchListTile(
      title: const Text('Show Coverage Boxes'),
      value: _showCoverage,
      onChanged: (value) async {
        _updateMapState(() {
          _showCoverage = value;
        });
        setModalState(() {});
        await _settingsService.setShowCoverage(value);
      },
    ),
    SwitchListTile(
      title: const Text('Show Samples'),
      value: _showSamples,
      onChanged: (value) async {
        _updateMapState(() {
          _showSamples = value;
        });
        setModalState(() {});
        await _settingsService.setShowSamples(value);
      },
    ),
    SwitchListTile(
      title: const Text('Show Edges'),
      value: _showEdges,
      onChanged: (value) async {
        _updateMapState(() {
          _showEdges = value;
        });
        setModalState(() {});
        await _settingsService.setShowEdges(value);
      },
    ),
    SwitchListTile(
      title: const Text('Show Repeaters'),
      value: _showRepeaters,
      onChanged: (value) async {
        _updateMapState(() {
          _showRepeaters = value;
        });
        setModalState(() {});
        await _settingsService.setShowRepeaters(value);
      },
    ),
    SwitchListTile(
      title: const Text('Show GPS Samples'),
      subtitle: const Text('Show blue GPS-only markers'),
      value: _showGpsSamples,
      onChanged: (value) async {
        _updateMapState(() {
          _showGpsSamples = value;
        });
        setModalState(() {});
        await _settingsService.setShowGpsSamples(value);
      },
    ),
    SwitchListTile(
      title: const Text('Show Successful Pings Only'),
      subtitle: const Text('Hide failed pings and GPS-only samples'),
      value: _showSuccessfulOnly,
      onChanged: (value) async {
        _updateMapState(() {
          _showSuccessfulOnly = value;
        });
        setModalState(() {});
        await _settingsService.setShowSuccessfulOnly(value);
      },
    ),
    SwitchListTile(
      title: const Text('Show Route Trail'),
      subtitle: const Text('Draw driven path on map'),
      value: _showRouteTrail,
      onChanged: (value) async {
        _updateMapState(() {
          _showRouteTrail = value;
        });
        setModalState(() {});
        await _settingsService.setShowRouteTrail(value);
      },
    ),
    SwitchListTile(
      title: const Text('Community Coverage'),
      subtitle: Text(
        _communityCoverage != null
            ? 'Show downloaded coverage from web map'
            : 'Download first from Data Management',
      ),
      value: _showCommunityCoverage,
      onChanged: _communityCoverage != null
          ? (value) {
              _updateMapState(() {
                _showCommunityCoverage = value;
              });
              setModalState(() {});
            }
          : null,
      secondary: _communityCoverage != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Clear downloaded coverage',
              onPressed: () async {
                await _uploadService.clearCachedCoverage();
                _updateMapState(() {
                  _communityCoverage = null;
                  _showCommunityCoverage = false;
                });
                setModalState(() {});
                _showSnackBar('Community coverage cleared');
              },
            )
          : null,
    ),
    SwitchListTile(
      title: const Text('Show Heatmap'),
      subtitle: const Text('Heat gradient overlay of ping activity'),
      value: _showHeatmap,
      onChanged: (value) async {
        _updateMapState(() {
          _showHeatmap = value;
        });
        setModalState(() {});
        await _settingsService.setShowHeatmap(value);
        // Trigger heatmap rebuild
        _heatmapRebuildStream.add(null);
      },
    ),
    SwitchListTile(
      title: const Text('Show Prediction Rings'),
      subtitle: const Text('Estimated repeater coverage radius'),
      value: _showPredictionRings,
      onChanged: (value) async {
        _updateMapState(() {
          _showPredictionRings = value;
        });
        setModalState(() {});
        await _settingsService.setShowPredictionRings(value);
      },
    ),
  ];
}
