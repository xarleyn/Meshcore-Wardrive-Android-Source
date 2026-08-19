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
    ListTile(
      leading: const Icon(Icons.gps_fixed),
      title: const Text('Location Quality Filters'),
      subtitle: const Text(
        'Accuracy, implausible movement, and impossible locations',
      ),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => _openLocationQualitySettings(context),
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
