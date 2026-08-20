part of '../../map_screen.dart';

extension _LocationQualitySettingsSection on _MapScreenState {
  void _openLocationQualitySettings(BuildContext context) async {
    await _loadImpossibleZones();
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen.category(
          title: AppLocalizations.of(context).settingsLocationQualityFilters,
          contentBuilder: (context, setPageState, scrollController) => ListView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: _buildLocationQualitySettings(context, setPageState),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLocationQualitySettings(
    BuildContext context,
    StateSetter setPageState,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      SettingsSectionHeader(
        title: l10n.settingsSectionThresholds,
        icon: Icons.gps_fixed,
      ),
      ListTile(
        title: Text(l10n.settingsMaxHorizontalError),
        subtitle: Text(l10n.settingsMaxHorizontalErrorSubtitle),
        trailing: Text(
          '${_formatLocationQualityValue(_locationQualitySettings.maxHorizontalAccuracyMeters)} m',
        ),
        onTap: () => _editLocationQualityValue(
          title: l10n.settingsMaxHorizontalError,
          description: l10n.settingsMaxHorizontalErrorDescription,
          unit: 'm',
          displayedValue: _locationQualitySettings.maxHorizontalAccuracyMeters,
          update: (value) => _locationQualitySettings.copyWith(
            maxHorizontalAccuracyMeters: value,
          ),
          setModalState: setPageState,
        ),
      ),
      ListTile(
        title: Text(l10n.settingsAirborneAltitude),
        subtitle: Text(l10n.settingsAirborneAltitudeSubtitle),
        trailing: Text(
          '${_formatLocationQualityValue(_locationQualitySettings.airborneAltitudeMeters)} m',
        ),
        onTap: () => _editLocationQualityValue(
          title: l10n.settingsAirborneAltitude,
          description: l10n.settingsAirborneAltitudeDescription,
          unit: 'm',
          displayedValue: _locationQualitySettings.airborneAltitudeMeters,
          update: (value) =>
              _locationQualitySettings.copyWith(airborneAltitudeMeters: value),
          setModalState: setPageState,
        ),
      ),
      ListTile(
        title: Text(l10n.settingsAirborneSpeed),
        subtitle: Text(l10n.settingsAirborneSpeedSubtitle),
        trailing: Text(
          '${_formatLocationQualityValue(_locationQualitySettings.airborneSpeedMetersPerSecond * 3.6)} km/h',
        ),
        onTap: () => _editLocationQualityValue(
          title: l10n.settingsAirborneSpeed,
          description: l10n.settingsAirborneSpeedDescription,
          unit: 'km/h',
          displayedValue:
              _locationQualitySettings.airborneSpeedMetersPerSecond * 3.6,
          update: (value) => _locationQualitySettings.copyWith(
            airborneSpeedMetersPerSecond: value / 3.6,
          ),
          setModalState: setPageState,
        ),
      ),
      ListTile(
        title: Text(l10n.settingsMaxWardriveSpeed),
        subtitle: Text(l10n.settingsMaxWardriveSpeedSubtitle),
        trailing: Text(
          '${_formatLocationQualityValue(_locationQualitySettings.maxWardriveSpeedMetersPerSecond * 3.6)} km/h',
        ),
        onTap: () => _editLocationQualityValue(
          title: l10n.settingsMaxWardriveSpeed,
          description: l10n.settingsMaxWardriveSpeedDescription,
          unit: 'km/h',
          displayedValue:
              _locationQualitySettings.maxWardriveSpeedMetersPerSecond * 3.6,
          update: (value) => _locationQualitySettings.copyWith(
            maxWardriveSpeedMetersPerSecond: value / 3.6,
          ),
          setModalState: setPageState,
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 8),
          child: TextButton.icon(
            onPressed: () => _resetLocationQualitySettings(setPageState),
            icon: const Icon(Icons.restore),
            label: Text(l10n.settingsRestoreDefaults),
          ),
        ),
      ),
      SettingsSectionHeader(
        title: l10n.settingsSectionImpossibleZones,
        icon: Icons.block_outlined,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          l10n.settingsImpossibleZonesBlurb,
          style: const TextStyle(fontSize: 13),
        ),
      ),
      ListTile(
        title: Text(l10n.settingsAddImpossibleZone),
        subtitle: Text(
          _impossibleZones.isEmpty
              ? l10n.settingsImpossibleZoneEmptySubtitle
              : l10n.settingsImpossibleZoneCount(_impossibleZones.length),
        ),
        leading: const Icon(Icons.add_location_alt_outlined),
        onTap: () async {
          final center = _currentPosition ?? _mapController.camera.center;
          await _addImpossibleZone(center);
          setPageState(() {});
        },
      ),
      ..._impossibleZones.map(
        (zone) => ListTile(
          title: Text(
            (zone.label != null && zone.label!.isNotEmpty)
                ? zone.label!
                : l10n.settingsUnnamedZone,
          ),
          subtitle: Text(
            '${zone.lat.toStringAsFixed(5)}, ${zone.lon.toStringAsFixed(5)} · '
            '${zone.radiusMeters.toStringAsFixed(0)} m',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.settingsDeleteZoneTooltip,
            onPressed: () async {
              final id = zone.id;
              if (id == null) return;
              await _databaseService.deleteImpossibleZone(id);
              await _loadImpossibleZones();
              setPageState(() {});
            },
          ),
        ),
      ),
      if (_impossibleZones.isNotEmpty)
        ListTile(
          title: Text(l10n.settingsClearImpossibleZones),
          subtitle: Text(l10n.settingsRemoveAllZones(_impossibleZones.length)),
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                final l10n = AppLocalizations.of(ctx);
                return AlertDialog(
                  title: Text(l10n.settingsClearImpossibleZones),
                  content: Text(l10n.settingsClearImpossibleZonesConfirm),
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
              for (final zone in _impossibleZones) {
                final id = zone.id;
                if (id != null) {
                  await _databaseService.deleteImpossibleZone(id);
                }
              }
              await _loadImpossibleZones();
              setPageState(() {});
            }
          },
        ),
    ];
  }

  Future<void> _addImpossibleZone(LatLng center) async {
    final l10n = AppLocalizations.of(context);
    final radiusOptions = [
      {'label': l10n.settingsRadius500m, 'meters': 500.0},
      {'label': l10n.settingsRadius1km, 'meters': 1000.0},
      {'label': l10n.settingsRadius2km, 'meters': 2000.0},
      {'label': l10n.settingsRadius5km, 'meters': 5000.0},
    ];
    double selectedRadius = 1000.0;
    final labelController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final l10n = AppLocalizations.of(ctx);
          return AlertDialog(
            title: Text(l10n.settingsAddImpossibleZone),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsAddImpossibleZoneCenter(
                    center.latitude.toStringAsFixed(5),
                    center.longitude.toStringAsFixed(5),
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsAddImpossibleZoneBlurb,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: l10n.settingsLabelOptional,
                    hintText: l10n.settingsLabelHintAirport,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.settingsRadius,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                RadioGroup<double>(
                  groupValue: selectedRadius,
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedRadius = v);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final opt in radiusOptions)
                        RadioListTile<double>(
                          title: Text(opt['label'] as String),
                          value: opt['meters'] as double,
                          dense: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.settingsCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.settingsAddZone),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      await _databaseService.addImpossibleZone(
        center.latitude,
        center.longitude,
        selectedRadius,
        labelController.text.isEmpty ? null : labelController.text,
      );
      await _loadImpossibleZones();
      _showSnackBar(l10n.settingsImpossibleZoneAdded);
    }
  }
}
