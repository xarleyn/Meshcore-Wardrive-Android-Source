part of '../../map_screen.dart';

extension _LocationSettingsSection on _MapScreenState {
  List<Widget> _buildLocationSettings(
    BuildContext context,
    StateSetter setModalState,
  ) => [
    const SettingsSectionHeader(
      title: 'Location & positioning',
      icon: Icons.my_location,
    ),
    SwitchListTile(
      title: const Text('beaconDB Wi-Fi Positioning'),
      subtitle: const Text(
        'Prefer Wi-Fi location; sends nearby BSSIDs and signal '
        'levels to beaconDB. Cyan marker means Wi-Fi is active.',
      ),
      value: _beaconDbWifiPositioning,
      onChanged: (value) async {
        _updateMapState(() {
          _beaconDbWifiPositioning = value;
        });
        setModalState(() {});
        await _settingsService.setBeaconDbWifiPositioning(value);
        _locationService.setWifiPositioningEnabled(value);
        if (value) {
          _showSnackBar('beaconDB enabled: nearby BSSIDs will be shared');
          await _requestWifiScanThrottlingDisabled();
        }
      },
    ),
    const ListTile(
      leading: Icon(Icons.gps_fixed),
      title: Text('Location Quality Filters'),
      subtitle: Text('Accuracy and implausible-movement thresholds'),
    ),
    ListTile(
      title: const Text('Maximum Horizontal Error'),
      subtitle: const Text('Reject positions with worse reported accuracy'),
      trailing: Text(
        '${_formatLocationQualityValue(_locationQualitySettings.maxHorizontalAccuracyMeters)} m',
      ),
      onTap: () => _editLocationQualityValue(
        title: 'Maximum Horizontal Error',
        description:
            'Positions whose reported horizontal error is '
            'larger than this value are ignored.',
        unit: 'm',
        displayedValue: _locationQualitySettings.maxHorizontalAccuracyMeters,
        update: (value) => _locationQualitySettings.copyWith(
          maxHorizontalAccuracyMeters: value,
        ),
        setModalState: setModalState,
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
            'At or above this altitude, a position is '
            'ignored only when it also exceeds the '
            'airborne speed.',
        unit: 'm',
        displayedValue: _locationQualitySettings.airborneAltitudeMeters,
        update: (value) =>
            _locationQualitySettings.copyWith(airborneAltitudeMeters: value),
        setModalState: setModalState,
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
            'At or above this speed, a high-altitude '
            'position is treated as a probable flight.',
        unit: 'km/h',
        displayedValue:
            _locationQualitySettings.airborneSpeedMetersPerSecond * 3.6,
        update: (value) => _locationQualitySettings.copyWith(
          airborneSpeedMetersPerSecond: value / 3.6,
        ),
        setModalState: setModalState,
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
            'Positions moving at or above this speed are '
            'ignored as implausible wardrive data.',
        unit: 'km/h',
        displayedValue:
            _locationQualitySettings.maxWardriveSpeedMetersPerSecond * 3.6,
        update: (value) => _locationQualitySettings.copyWith(
          maxWardriveSpeedMetersPerSecond: value / 3.6,
        ),
        setModalState: setModalState,
      ),
    ),
    Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 8),
        child: TextButton.icon(
          onPressed: () => _resetLocationQualitySettings(setModalState),
          icon: const Icon(Icons.restore),
          label: const Text('Restore Defaults'),
        ),
      ),
    ),
    SwitchListTile(
      title: const Text('Show Approximate Position'),
      subtitle: const Text('Display the grey radio-position estimate'),
      value: _showRadioPosition,
      onChanged: (value) async {
        _updateMapState(() {
          _showRadioPosition = value;
        });
        setModalState(() {});
        await _settingsService.setShowRadioPosition(value);
      },
    ),
    ListTile(
      title: const Text('Ducting Forecast'),
      subtitle: const Text('6-day tropospheric ducting maps'),
      leading: const Icon(Icons.cloud),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DuctingForecastScreen(),
          ),
        );
      },
    ),
    SwitchListTile(
      title: const Text('Atmospheric Ducting'),
      subtitle: const Text('Monitor ducting conditions (needs internet)'),
      value: _showDucting,
      onChanged: (value) async {
        _updateMapState(() {
          _showDucting = value;
        });
        setModalState(() {});
        await _settingsService.setShowDucting(value);
        _locationService.setDuctingEnabled(value);
        if (value) {
          // Fetch immediately and update badge
          final risk = await _locationService.ductingService.getLatestRisk();
          _updateMapState(() {
            _currentDuctingRisk = risk;
          });
        }
      },
    ),
  ];
}
