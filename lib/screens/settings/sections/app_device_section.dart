part of '../../map_screen.dart';

extension _AppDeviceSettingsSection on _MapScreenState {
  List<Widget> _buildAppDeviceSettings(
    BuildContext context,
    StateSetter setModalState,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      SettingsSectionHeader(
        title: l10n.settingsSectionAppDevice,
        icon: Icons.tune,
      ),
      ListTile(
        title: Text(l10n.settingsDeviceName),
        subtitle: FutureBuilder<String?>(
          future: _settingsService.getDeviceName(),
          builder: (context, snap) =>
              Text(snap.data ?? l10n.settingsDeviceNameNotSet),
        ),
        leading: const Icon(Icons.badge),
        trailing: const Icon(Icons.edit, size: 20),
        onTap: () async {
          final current = await _settingsService.getDeviceName();
          if (!context.mounted) return;
          final result = await showSettingsTextInputDialog(
            context: context,
            title: l10n.settingsDeviceName,
            initialValue: current ?? '',
            labelText: l10n.settingsDeviceNameLabel,
            hintText: l10n.settingsDeviceNameHint,
          );
          if (result != null) {
            await _settingsService.setDeviceName(
              result.isEmpty ? null : result,
            );
            setModalState(() {});
          }
        },
      ),
      const Divider(),
      SwitchListTile(
        title: Text(l10n.settingsKeepScreenOn),
        subtitle: Text(l10n.settingsKeepScreenOnSubtitle),
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
        title: Text(l10n.settingsBatterySaver),
        subtitle: Text(l10n.settingsBatterySaverSubtitle),
        secondary: const Icon(Icons.battery_saver),
        value: _batterySaverEnabled,
        onChanged: (value) async {
          _updateMapState(() {
            _batterySaverEnabled = value;
          });
          setModalState(() {});
          await _settingsService.setBatterySaverEnabled(value);
          _locationService.setBatterySaverEnabled(value);
        },
      ),
      SwitchListTile(
        title: Text(l10n.settingsLockMapRotation),
        subtitle: Text(l10n.settingsLockMapRotationSubtitle),
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
        title: Text(l10n.settingsCurrentLocationMarker),
        subtitle: Text(l10n.settingsCurrentLocationMarkerSubtitle),
        trailing: DropdownButton<CurrentLocationMarkerStyle>(
          value: _currentLocationMarkerStyle,
          items: [
            DropdownMenuItem(
              value: CurrentLocationMarkerStyle.circle,
              child: Text(l10n.settingsMarkerCircle),
            ),
            DropdownMenuItem(
              value: CurrentLocationMarkerStyle.arrow,
              child: Text(l10n.settingsMarkerDirectionArrow),
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
        title: Text(l10n.settingsCalibrateCompass),
        subtitle: Text(l10n.settingsCalibrateCompassSubtitle),
        leading: const Icon(Icons.explore),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(context);
          _openCompassCalibration(snoozeOnDismiss: false);
        },
      ),
      ListTile(
        title: Text(l10n.settingsInterfaceTheme),
        subtitle: Text(_getInterfaceThemeModeText()),
        trailing: const Icon(Icons.brightness_6),
        onTap: () {
          Navigator.pop(context);
          _showInterfaceThemeSelector();
        },
      ),
      ListTile(
        title: Text(l10n.settingsMapTheme),
        subtitle: Text(_getMapThemeModeText()),
        trailing: const Icon(Icons.map_outlined),
        onTap: () {
          Navigator.pop(context);
          _showMapThemeSelector();
        },
      ),
      ListTile(
        title: Text(l10n.language),
        subtitle: Text(_getAppLocalePreferenceText()),
        trailing: const Icon(Icons.language),
        onTap: () {
          Navigator.pop(context);
          _showLanguageSelector();
        },
      ),
      if (_loraConnected)
        ListTile(
          title: Text(l10n.settingsScanForRepeaters),
          subtitle: Text(
            _repeaters.isEmpty
                ? l10n.settingsScanFindNearby
                : l10n.settingsRepeatersFound(_repeaters.length),
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
          title: Text(l10n.settingsRefreshContactList),
          subtitle: Text(l10n.settingsRefreshContactListSubtitle),
          leading: const Icon(Icons.refresh),
          onTap: () {
            Navigator.pop(context);
            _refreshContacts();
          },
        ),
      ListTile(
        title: Text(l10n.settingsColorMode),
        trailing: DropdownButton<String>(
          value: _colorMode,
          items: [
            DropdownMenuItem(
              value: 'quality',
              child: Text(l10n.settingsColorModeQuality),
            ),
            DropdownMenuItem(
              value: 'age',
              child: Text(l10n.settingsColorModeAge),
            ),
            DropdownMenuItem(
              value: 'redundancy',
              child: Text(l10n.settingsColorModeRedundancy),
            ),
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
        title: Text(l10n.settingsDistanceUnit),
        trailing: DropdownButton<String>(
          value: _distanceUnit,
          items: [
            DropdownMenuItem(value: 'miles', child: Text(l10n.settingsMiles)),
            DropdownMenuItem(value: 'km', child: Text(l10n.settingsKilometers)),
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
        title: Text(l10n.settingsFuelUnit),
        trailing: DropdownButton<String>(
          value: _fuelUnit,
          items: [
            DropdownMenuItem(
              value: 'imperial',
              child: Text(l10n.settingsFuelUnitImperial),
            ),
            DropdownMenuItem(
              value: 'metric',
              child: Text(l10n.settingsFuelUnitMetric),
            ),
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
        title: Text(l10n.settingsColorBlindMode),
        trailing: DropdownButton<String>(
          value: _colorBlindMode,
          items: [
            DropdownMenuItem(
              value: 'normal',
              child: Text(l10n.settingsColorBlindNormal),
            ),
            DropdownMenuItem(
              value: 'deuteranopia',
              child: Text(l10n.settingsColorBlindDeuteranopia),
            ),
            DropdownMenuItem(
              value: 'protanopia',
              child: Text(l10n.settingsColorBlindProtanopia),
            ),
            DropdownMenuItem(
              value: 'tritanopia',
              child: Text(l10n.settingsColorBlindTritanopia),
            ),
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
}
