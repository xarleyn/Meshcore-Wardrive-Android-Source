part of '../../map_screen.dart';

extension _MapDisplaySettingsSection on _MapScreenState {
  List<Widget> _buildMapDisplaySettings(StateSetter setModalState) {
    final l10n = AppLocalizations.of(context);
    return [
      SettingsSectionHeader(
        title: l10n.settingsSectionMapDisplay,
        icon: Icons.map_outlined,
      ),
      SwitchListTile(
        title: Text(l10n.settingsShowCoverageBoxes),
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
        title: Text(l10n.settingsSimplifyMapAtLowZoom),
        subtitle: Text(l10n.settingsSimplifyMapAtLowZoomSubtitle),
        value: _mapLodEnabled,
        onChanged: (value) async {
          _updateMapState(() {
            _mapLodEnabled = value;
          });
          setModalState(() {});
          await _settingsService.setMapLodEnabled(value);
        },
      ),
      SwitchListTile(
        title: Text(l10n.settingsShowSamples),
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
        title: Text(l10n.settingsShowEdges),
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
        title: Text(l10n.settingsShowRepeaters),
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
        title: Text(l10n.settingsShowGpsSamples),
        subtitle: Text(l10n.settingsShowGpsSamplesSubtitle),
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
        title: Text(l10n.settingsShowSuccessfulPingsOnly),
        subtitle: Text(l10n.settingsShowSuccessfulPingsOnlySubtitle),
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
        title: Text(l10n.settingsShowRouteTrail),
        subtitle: Text(l10n.settingsShowRouteTrailSubtitle),
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
        title: Text(l10n.settingsCommunityCoverage),
        subtitle: Text(
          _communityCoverage != null
              ? l10n.settingsCommunityCoverageDownloaded
              : l10n.settingsCommunityCoverageNeedDownload,
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
                tooltip: l10n.settingsClearDownloadedCoverageTooltip,
                onPressed: () async {
                  await _uploadService.clearCachedCoverage();
                  _updateMapState(() {
                    _communityCoverage = null;
                    _showCommunityCoverage = false;
                  });
                  setModalState(() {});
                  _showSnackBar(l10n.settingsCommunityCoverageCleared);
                },
              )
            : null,
      ),
      SwitchListTile(
        title: Text(l10n.settingsShowHeatmap),
        subtitle: Text(l10n.settingsShowHeatmapSubtitle),
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
        title: Text(l10n.settingsShowPredictionRings),
        subtitle: Text(l10n.settingsShowPredictionRingsSubtitle),
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
}
