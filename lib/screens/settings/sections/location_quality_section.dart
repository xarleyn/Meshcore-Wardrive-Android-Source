part of '../../map_screen.dart';

extension _LocationQualitySettingsSection on _MapScreenState {
  void _openLocationQualitySettings(BuildContext context) async {
    await _loadImpossibleZones();
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen.category(
          title: 'Location Quality Filters',
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
  ) => [
    const SettingsSectionHeader(title: 'Thresholds', icon: Icons.gps_fixed),
    ListTile(
      title: const Text('Maximum Horizontal Error'),
      subtitle: const Text('Reject positions with worse reported accuracy'),
      trailing: Text(
        '${_formatLocationQualityValue(_locationQualitySettings.maxHorizontalAccuracyMeters)} m',
      ),
      onTap: () => _editLocationQualityValue(
        title: 'Maximum Horizontal Error',
        description:
            'Positions whose reported horizontal error is larger than this '
            'value are ignored.',
        unit: 'm',
        displayedValue: _locationQualitySettings.maxHorizontalAccuracyMeters,
        update: (value) => _locationQualitySettings.copyWith(
          maxHorizontalAccuracyMeters: value,
        ),
        setModalState: setPageState,
      ),
    ),
    ListTile(
      title: const Text('Airborne Altitude'),
      subtitle: const Text('Altitude used together with airborne speed'),
      trailing: Text(
        '${_formatLocationQualityValue(_locationQualitySettings.airborneAltitudeMeters)} m',
      ),
      onTap: () => _editLocationQualityValue(
        title: 'Airborne Altitude',
        description:
            'At or above this altitude, a position is ignored only when it '
            'also exceeds the airborne speed.',
        unit: 'm',
        displayedValue: _locationQualitySettings.airborneAltitudeMeters,
        update: (value) =>
            _locationQualitySettings.copyWith(airborneAltitudeMeters: value),
        setModalState: setPageState,
      ),
    ),
    ListTile(
      title: const Text('Airborne Speed'),
      subtitle: const Text('Speed used together with airborne altitude'),
      trailing: Text(
        '${_formatLocationQualityValue(_locationQualitySettings.airborneSpeedMetersPerSecond * 3.6)} km/h',
      ),
      onTap: () => _editLocationQualityValue(
        title: 'Airborne Speed',
        description:
            'At or above this speed, a high-altitude position is treated as '
            'a probable flight.',
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
      title: const Text('Maximum Wardrive Speed'),
      subtitle: const Text('Reject positions moving faster than this'),
      trailing: Text(
        '${_formatLocationQualityValue(_locationQualitySettings.maxWardriveSpeedMetersPerSecond * 3.6)} km/h',
      ),
      onTap: () => _editLocationQualityValue(
        title: 'Maximum Wardrive Speed',
        description:
            'Positions moving at or above this speed are ignored as '
            'implausible wardrive data.',
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
          label: const Text('Restore Defaults'),
        ),
      ),
    ),
    const SettingsSectionHeader(
      title: 'Impossible Zones',
      icon: Icons.block_outlined,
    ),
    const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        'Places you cannot physically be. GPS inside a zone is discarded '
        'and the last valid position is kept. Zones are not shown on the map.',
        style: TextStyle(fontSize: 13),
      ),
    ),
    ListTile(
      title: const Text('Add Impossible Zone'),
      subtitle: Text(
        _impossibleZones.isEmpty
            ? 'Uses current position or map center'
            : '${_impossibleZones.length} zone(s)',
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
              : 'Unnamed zone',
        ),
        subtitle: Text(
          '${zone.lat.toStringAsFixed(5)}, ${zone.lon.toStringAsFixed(5)} · '
          '${zone.radiusMeters.toStringAsFixed(0)} m',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete zone',
          onPressed: () async {
            final id = zone.id;
            if (id == null) return;
            await DatabaseService().deleteImpossibleZone(id);
            await _loadImpossibleZones();
            setPageState(() {});
          },
        ),
      ),
    ),
    if (_impossibleZones.isNotEmpty)
      ListTile(
        title: const Text('Clear Impossible Zones'),
        subtitle: Text('Remove all ${_impossibleZones.length} zone(s)'),
        leading: const Icon(Icons.delete_outline, color: Colors.red),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Clear Impossible Zones'),
              content: const Text(
                'Remove all impossible zones? GPS inside those areas will '
                'no longer be discarded.',
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
            for (final zone in _impossibleZones) {
              final id = zone.id;
              if (id != null) {
                await DatabaseService().deleteImpossibleZone(id);
              }
            }
            await _loadImpossibleZones();
            setPageState(() {});
          }
        },
      ),
  ];

  Future<void> _addImpossibleZone(LatLng center) async {
    final radiusOptions = [
      {'label': '500m (~0.3 mi)', 'meters': 500.0},
      {'label': '1 km (~0.6 mi)', 'meters': 1000.0},
      {'label': '2 km (~1.2 mi)', 'meters': 2000.0},
      {'label': '5 km (~3 mi)', 'meters': 5000.0},
    ];
    double selectedRadius = 1000.0;
    final labelController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Impossible Zone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Center: ${center.latitude.toStringAsFixed(5)}, ${center.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'GPS inside this area is treated as invalid and discarded.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Label (optional)',
                  hintText: 'e.g., Airport',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Radius:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              ...radiusOptions.map(
                (opt) => RadioListTile<double>(
                  title: Text(opt['label'] as String),
                  value: opt['meters'] as double,
                  groupValue: selectedRadius,
                  onChanged: (v) => setDialogState(() => selectedRadius = v!),
                  dense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add Zone'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await DatabaseService().addImpossibleZone(
        center.latitude,
        center.longitude,
        selectedRadius,
        labelController.text.isEmpty ? null : labelController.text,
      );
      await _loadImpossibleZones();
      _showSnackBar('Impossible zone added');
    }
  }
}
