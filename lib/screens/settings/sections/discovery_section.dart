part of '../../map_screen.dart';

extension _DiscoverySettingsSection on _MapScreenState {
  List<Widget> _buildDiscoverySettings(
    BuildContext context,
    StateSetter setModalState,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      SettingsSectionHeader(
        title: l10n.settingsSectionDiscovery,
        icon: Icons.radar,
      ),
      ListTile(
        title: Text(l10n.settingsDiscoveryTimeout),
        subtitle: Text(l10n.settingsDiscoveryTimeoutSubtitle),
        trailing: DiscoveryTimeoutDropdown(
          value: _discoveryTimeoutSeconds,
          isDense: false,
          itemStyle: null,
          onChanged: (value) async {
            _updateMapState(() {
              _discoveryTimeoutSeconds = value;
            });
            setModalState(() {});
            await _settingsService.setDiscoveryTimeout(value);
          },
        ),
      ),
      SwitchListTile(
        title: Text(l10n.settingsThoroughResponseCollection),
        subtitle: Text(
          _thoroughResponseCollection
              ? l10n.settingsThoroughOn
              : l10n.settingsThoroughOff,
        ),
        value: _thoroughResponseCollection,
        onChanged: (value) async {
          _updateMapState(() {
            _thoroughResponseCollection = value;
          });
          setModalState(() {});
          await _settingsService.setThoroughResponseCollection(value);
        },
      ),
      ListTile(
        title: Text(l10n.settingsIgnoreRepeaters),
        subtitle: Text(
          _ignoredRepeaterPrefix != null && _ignoredRepeaterPrefix!.isNotEmpty
              ? l10n.settingsIgnoringPrefix(_ignoredRepeaterPrefix!)
              : l10n.settingsNotFiltering,
        ),
        trailing: const Icon(Icons.edit),
        onTap: () {
          Navigator.pop(context);
          _setIgnoredRepeater();
        },
      ),
      ListTile(
        title: Text(l10n.settingsIncludeOnlyRepeaters),
        subtitle: Text(
          _includeOnlyRepeaters != null && _includeOnlyRepeaters!.isNotEmpty
              ? l10n.settingsWhitelistPrefix(_includeOnlyRepeaters!)
              : l10n.settingsShowAllRepeaters,
        ),
        trailing: const Icon(Icons.edit),
        onTap: () {
          Navigator.pop(context);
          _setIncludeOnlyRepeaters();
        },
      ),
      SwitchListTile(
        title: Text(l10n.settingsApplyWhitelistToEdges),
        subtitle: Text(l10n.settingsApplyWhitelistToEdgesSubtitle),
        value: _filterEdgesByWhitelist,
        onChanged: (value) async {
          _updateMapState(() {
            _filterEdgesByWhitelist = value;
          });
          setModalState(() {});
          await _settingsService.setFilterEdgesByWhitelist(value);
        },
      ),
      ListTile(
        title: Text(l10n.settingsPingMode),
        trailing: DropdownButton<String>(
          value: _pingMode,
          items: [
            DropdownMenuItem(
              value: 'distance',
              child: Text(l10n.settingsPingModeDistance),
            ),
            DropdownMenuItem(
              value: 'time',
              child: Text(l10n.settingsPingModeTime),
            ),
            DropdownMenuItem(
              value: 'both',
              child: Text(l10n.settingsPingModeBoth),
            ),
          ],
          onChanged: (value) async {
            _updateMapState(() {
              _pingMode = value!;
            });
            setModalState(() {});
            await _settingsService.setPingMode(value!);
            _locationService.setPingMode(value);
          },
        ),
      ),
      if (_pingMode != 'time')
        ListTile(
          title: Text(l10n.settingsPingDistance),
          subtitle: Text(_getPingIntervalDescription()),
          trailing: const Icon(Icons.tune),
          onTap: () {
            Navigator.pop(context);
            _setPingInterval();
          },
        ),
      if (_pingMode != 'distance')
        ListTile(
          title: Text(l10n.settingsPingTimeInterval),
          trailing: DropdownButton<int>(
            value: _pingTimeInterval,
            items: const [
              DropdownMenuItem(value: 5, child: Text('5s')),
              DropdownMenuItem(value: 10, child: Text('10s')),
              DropdownMenuItem(value: 15, child: Text('15s')),
              DropdownMenuItem(value: 20, child: Text('20s')),
              DropdownMenuItem(value: 25, child: Text('25s')),
              DropdownMenuItem(value: 30, child: Text('30s')),
              DropdownMenuItem(value: 45, child: Text('45s')),
              DropdownMenuItem(value: 60, child: Text('60s')),
              DropdownMenuItem(value: 120, child: Text('2m')),
              DropdownMenuItem(value: 300, child: Text('5m')),
            ],
            onChanged: (value) async {
              _updateMapState(() {
                _pingTimeInterval = value!;
              });
              setModalState(() {});
              await _settingsService.setPingTimeInterval(value!);
              _locationService.setPingTimeInterval(value);
            },
          ),
        ),
      ListTile(
        title: Text(l10n.settingsCoverageResolution),
        subtitle: Text(_getCoverageResolutionDescription()),
        trailing: const Icon(Icons.grid_on),
        onTap: () {
          Navigator.pop(context);
          _setCoverageResolution();
        },
      ),
    ];
  }
}
