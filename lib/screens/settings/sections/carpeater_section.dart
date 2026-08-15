part of '../../map_screen.dart';

extension _CarpeaterSettingsSection on _MapScreenState {
  List<Widget> _buildCarpeaterSettings(
    BuildContext context,
    StateSetter setModalState,
  ) => [
    const SettingsSectionHeader(
      title: 'Carpeater mode (Beta)',
      icon: Icons.cell_tower,
    ),
    SwitchListTile(
      title: const Text('Enable Carpeater Mode'),
      subtitle: Text(
        _carpeaterEnabled
            ? 'Using repeater for discovery'
            : 'Use a repeater to discover neighbors\nRequires v1.14+ firmware on all repeaters',
      ),
      value: _carpeaterEnabled,
      onChanged: (value) async {
        _updateMapState(() {
          _carpeaterEnabled = value;
        });
        setModalState(() {});
        await _settingsService.setCarpeaterEnabled(value);
        _locationService.setCarpeaterMode(value);
        // Sync auto-ping UI state after mode switch
        _updateMapState(() {
          _autoPingEnabled = _locationService.isAutoPingEnabled;
        });
      },
    ),
    if (_carpeaterEnabled) ...[
      ListTile(
        title: const Text('Target Repeater'),
        subtitle: Text(_carpeaterRepeaterId ?? 'Not set'),
        leading: const Icon(Icons.cell_tower),
        trailing: const Icon(Icons.edit, size: 20),
        onTap: () async {
          final controller = TextEditingController(
            text: _carpeaterRepeaterId ?? '',
          );
          final result = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Target Repeater'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Repeater ID Prefix',
                  hintText: 'e.g., BAD5DC49',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (result != null) {
            _updateMapState(() {
              _carpeaterRepeaterId = result.isEmpty ? null : result;
            });
            setModalState(() {});
            await _settingsService.setCarpeaterRepeaterId(
              result.isEmpty ? null : result,
            );
          }
        },
      ),
      ListTile(
        title: const Text('Admin Password'),
        subtitle: Text(
          _carpeaterPassword != null
              ? '•' * _carpeaterPassword!.length
              : 'Not set',
        ),
        leading: const Icon(Icons.lock),
        trailing: const Icon(Icons.edit, size: 20),
        onTap: () async {
          final controller = TextEditingController(
            text: _carpeaterPassword ?? '',
          );
          final result = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Admin Password'),
              content: TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Repeater admin password',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (result != null) {
            _updateMapState(() {
              _carpeaterPassword = result.isEmpty ? null : result;
            });
            setModalState(() {});
            await _settingsService.setCarpeaterPassword(
              result.isEmpty ? null : result,
            );
          }
        },
      ),
      ListTile(
        title: const Text('Cycle Interval'),
        subtitle: const Text('Time between discovery cycles'),
        trailing: DropdownButton<int>(
          value: _carpeaterInterval,
          items: const [
            DropdownMenuItem(value: 0, child: Text('None')),
            DropdownMenuItem(value: 5, child: Text('5s')),
            DropdownMenuItem(value: 10, child: Text('10s')),
            DropdownMenuItem(value: 15, child: Text('15s')),
            DropdownMenuItem(value: 30, child: Text('30s')),
            DropdownMenuItem(value: 60, child: Text('60s')),
            DropdownMenuItem(value: 120, child: Text('2m')),
          ],
          onChanged: (value) async {
            _updateMapState(() {
              _carpeaterInterval = value!;
            });
            setModalState(() {});
            await _settingsService.setCarpeaterInterval(value!);
          },
        ),
      ),
    ],
  ];
}
