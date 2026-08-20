part of '../../map_screen.dart';

extension _LocationSettingsSection on _MapScreenState {
  List<Widget> _buildLocationSettings(
    BuildContext context,
    StateSetter setModalState,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      SettingsSectionHeader(
        title: l10n.settingsSectionLocation,
        icon: Icons.my_location,
      ),
      SwitchListTile(
        title: Text(l10n.settingsBeaconDbWifi),
        subtitle: Text(l10n.settingsBeaconDbWifiSubtitle),
        value: _beaconDbWifiPositioning,
        onChanged: (value) async {
          _updateMapState(() {
            _beaconDbWifiPositioning = value;
          });
          setModalState(() {});
          await _settingsService.setBeaconDbWifiPositioning(value);
          _locationService.setWifiPositioningEnabled(value);
          if (value) {
            _showSnackBar(l10n.settingsBeaconDbEnabledSnack);
            await _requestWifiScanThrottlingDisabled();
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.gps_fixed),
        title: Text(l10n.settingsLocationQualityFilters),
        subtitle: Text(l10n.settingsLocationQualityFiltersSubtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => _openLocationQualitySettings(context),
      ),
      SwitchListTile(
        title: Text(l10n.settingsShowApproximatePosition),
        subtitle: Text(l10n.settingsShowApproximatePositionSubtitle),
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
        title: Text(l10n.settingsDuctingForecast),
        subtitle: Text(l10n.settingsDuctingForecastSubtitle),
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
        title: Text(l10n.settingsAtmosphericDucting),
        subtitle: Text(l10n.settingsAtmosphericDuctingSubtitle),
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
}
