part of '../../map_screen.dart';

extension _DiscoverySettingsSection on _MapScreenState {
  List<Widget> _buildDiscoverySettings(
    BuildContext context,
    StateSetter setModalState,
  ) => [
    const SettingsSectionHeader(
      title: 'Discovery & sampling',
      icon: Icons.radar,
    ),
    ListTile(
      title: const Text('Discovery Timeout'),
      subtitle: const Text('How long to wait for repeater responses'),
      trailing: DropdownButton<int>(
        value: _discoveryTimeoutSeconds,
        items: const [
          DropdownMenuItem(value: 5, child: Text('5s')),
          DropdownMenuItem(value: 10, child: Text('10s')),
          DropdownMenuItem(value: 15, child: Text('15s')),
          DropdownMenuItem(value: 20, child: Text('20s')),
          DropdownMenuItem(value: 25, child: Text('25s')),
          DropdownMenuItem(value: 30, child: Text('30s')),
        ],
        onChanged: (value) async {
          _updateMapState(() {
            _discoveryTimeoutSeconds = value!;
          });
          setModalState(() {});
          await _settingsService.setDiscoveryTimeout(value!);
        },
      ),
    ),
    SwitchListTile(
      title: const Text('Thorough Response Collection'),
      subtitle: Text(
        _thoroughResponseCollection
            ? 'Thorough: collect responses until the discovery timeout'
            : 'Fast: finish 3 seconds after the first response',
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
      title: const Text('Ignore Repeaters'),
      subtitle: Text(
        _ignoredRepeaterPrefix != null && _ignoredRepeaterPrefix!.isNotEmpty
            ? 'Ignoring: $_ignoredRepeaterPrefix'
            : 'Not filtering',
      ),
      trailing: const Icon(Icons.edit),
      onTap: () {
        Navigator.pop(context);
        _setIgnoredRepeater();
      },
    ),
    ListTile(
      title: const Text('Include Only Repeaters'),
      subtitle: Text(
        _includeOnlyRepeaters != null && _includeOnlyRepeaters!.isNotEmpty
            ? 'Whitelist: $_includeOnlyRepeaters'
            : 'Show all repeaters',
      ),
      trailing: const Icon(Icons.edit),
      onTap: () {
        Navigator.pop(context);
        _setIncludeOnlyRepeaters();
      },
    ),
    SwitchListTile(
      title: const Text('Apply Whitelist to Edges'),
      subtitle: const Text('Only show edges for whitelisted repeaters'),
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
      title: const Text('Ping Mode'),
      trailing: DropdownButton<String>(
        value: _pingMode,
        items: const [
          DropdownMenuItem(value: 'distance', child: Text('Distance')),
          DropdownMenuItem(value: 'time', child: Text('Time')),
          DropdownMenuItem(value: 'both', child: Text('Both')),
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
        title: const Text('Ping Distance'),
        subtitle: Text(_getPingIntervalDescription()),
        trailing: const Icon(Icons.tune),
        onTap: () {
          Navigator.pop(context);
          _setPingInterval();
        },
      ),
    if (_pingMode != 'distance')
      ListTile(
        title: const Text('Ping Time Interval'),
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
      title: const Text('Coverage Resolution'),
      subtitle: Text(_getCoverageResolutionDescription()),
      trailing: const Icon(Icons.grid_on),
      onTap: () {
        Navigator.pop(context);
        _setCoverageResolution();
      },
    ),
  ];
}
