part of '../../map_screen.dart';

extension _AppDeviceSettingsSection on _MapScreenState {
  List<Widget> _buildAppDeviceSettings(
    BuildContext context,
    StateSetter setModalState,
  ) => [
    const SettingsSectionHeader(title: 'App & device', icon: Icons.tune),
    ListTile(
      title: const Text('Device Name'),
      subtitle: FutureBuilder<String?>(
        future: _settingsService.getDeviceName(),
        builder: (context, snap) =>
            Text(snap.data ?? 'Not set — used for multi-device wardrive'),
      ),
      leading: const Icon(Icons.badge),
      trailing: const Icon(Icons.edit, size: 20),
      onTap: () async {
        final current = await _settingsService.getDeviceName();
        if (!context.mounted) return;
        final result = await showSettingsTextInputDialog(
          context: context,
          title: 'Device Name',
          initialValue: current ?? '',
          labelText: 'Name',
          hintText: 'e.g., Chuck-Pixel',
        );
        if (result != null) {
          await _settingsService.setDeviceName(result.isEmpty ? null : result);
          setModalState(() {});
        }
      },
    ),
    const Divider(),
    SwitchListTile(
      title: const Text('Keep Screen On'),
      subtitle: const Text(
        'Prevent the screen from sleeping while the app is open',
      ),
      secondary: const Icon(Icons.screen_lock_portrait),
      value: _keepScreenOn,
      onChanged: (value) async {
        _updateMapState(() {
          _keepScreenOn = value;
        });
        setModalState(() {});
        await _settingsService.setKeepScreenOn(value);
        await ScreenWakeService.instance.setAlwaysOn(value);
      },
    ),
    SwitchListTile(
      title: const Text('Lock Map Rotation'),
      subtitle: const Text('Prevent map rotation'),
      value: _lockRotationNorth,
      onChanged: (value) async {
        _updateMapState(() {
          _lockRotationNorth = value;
          if (value) {
            _followHeading = false;
          }
        });
        if (value) {
          _mapController.rotate(0);
        }
        setModalState(() {});
        await _settingsService.setLockRotationNorth(value);
      },
    ),
    ListTile(
      title: const Text('Current Location Marker'),
      subtitle: const Text('The direction arrow follows the phone compass'),
      trailing: DropdownButton<CurrentLocationMarkerStyle>(
        value: _currentLocationMarkerStyle,
        items: const [
          DropdownMenuItem(
            value: CurrentLocationMarkerStyle.circle,
            child: Text('Circle'),
          ),
          DropdownMenuItem(
            value: CurrentLocationMarkerStyle.arrow,
            child: Text('Direction arrow'),
          ),
        ],
        onChanged: (value) async {
          if (value == null) return;
          _updateMapState(() {
            _currentLocationMarkerStyle = value;
            if (value == CurrentLocationMarkerStyle.circle) {
              _followHeading = false;
            }
          });
          if (value == CurrentLocationMarkerStyle.circle) {
            _mapController.rotate(0);
          }
          setModalState(() {});
          _syncCompassSubscription();
          await _settingsService.setCurrentLocationMarkerStyle(value);
        },
      ),
    ),
    ListTile(
      title: const Text('Theme'),
      subtitle: Text(_getThemeModeText()),
      trailing: const Icon(Icons.brightness_6),
      onTap: () {
        Navigator.pop(context);
        _showThemeSelector();
      },
    ),
    if (_loraConnected)
      ListTile(
        title: const Text('Scan for Repeaters'),
        subtitle: Text(
          _repeaters.isEmpty
              ? 'Find nearby LoRa nodes'
              : '${_repeaters.length} repeater(s) found',
        ),
        leading: const Icon(Icons.cell_tower),
        trailing: const Icon(Icons.search),
        onTap: () {
          Navigator.pop(context);
          _scanForRepeaters();
        },
      ),
    if (_loraConnected)
      ListTile(
        title: const Text('Refresh Contact List'),
        subtitle: const Text('Update repeater names from device'),
        leading: const Icon(Icons.refresh),
        onTap: () {
          Navigator.pop(context);
          _refreshContacts();
        },
      ),
    ListTile(
      title: const Text('Color Mode'),
      trailing: DropdownButton<String>(
        value: _colorMode,
        items: const [
          DropdownMenuItem(value: 'quality', child: Text('Quality')),
          DropdownMenuItem(value: 'age', child: Text('Age')),
          DropdownMenuItem(value: 'redundancy', child: Text('Redundancy')),
        ],
        onChanged: (value) async {
          _updateMapState(() {
            _colorMode = value!;
          });
          await _settingsService.setColorMode(value!);
        },
      ),
    ),
    ListTile(
      title: const Text('Distance Unit'),
      trailing: DropdownButton<String>(
        value: _distanceUnit,
        items: const [
          DropdownMenuItem(value: 'miles', child: Text('Miles')),
          DropdownMenuItem(value: 'km', child: Text('Kilometers')),
        ],
        onChanged: (value) async {
          _updateMapState(() {
            _distanceUnit = value!;
            // Update displayed distance immediately
            _totalDistance = value == 'miles'
                ? _locationService.totalDistanceMiles
                : _locationService.totalDistanceKm;
          });
          setModalState(() {});
          await _settingsService.setDistanceUnit(value!);
        },
      ),
    ),
    ListTile(
      title: const Text('Fuel Unit'),
      trailing: DropdownButton<String>(
        value: _fuelUnit,
        items: const [
          DropdownMenuItem(value: 'imperial', child: Text('MPG / Gallons')),
          DropdownMenuItem(value: 'metric', child: Text('L/100km / Litres')),
        ],
        onChanged: (value) async {
          _updateMapState(() {
            _fuelUnit = value!;
          });
          setModalState(() {});
          await _settingsService.setFuelUnit(value!);
        },
      ),
    ),
    ListTile(
      title: const Text('Color Blind Mode'),
      trailing: DropdownButton<String>(
        value: _colorBlindMode,
        items: const [
          DropdownMenuItem(value: 'normal', child: Text('Normal')),
          DropdownMenuItem(value: 'deuteranopia', child: Text('Deuteranopia')),
          DropdownMenuItem(value: 'protanopia', child: Text('Protanopia')),
          DropdownMenuItem(value: 'tritanopia', child: Text('Tritanopia')),
        ],
        onChanged: (value) async {
          _updateMapState(() {
            _colorBlindMode = value!;
          });
          setModalState(() {});
          await _settingsService.setColorBlindMode(value!);
        },
      ),
    ),
  ];
}
