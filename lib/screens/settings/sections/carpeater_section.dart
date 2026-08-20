part of '../../map_screen.dart';

extension _CarpeaterSettingsSection on _MapScreenState {
  List<Widget> _buildCarpeaterSettings(
    BuildContext context,
    StateSetter setModalState,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      SettingsSectionHeader(
        title: l10n.settingsSectionCarpeater,
        icon: Icons.cell_tower,
      ),
      SwitchListTile(
        title: Text(l10n.settingsEnableCarpeaterMode),
        subtitle: Text(
          _carpeaterEnabled
              ? l10n.settingsCarpeaterEnabledSubtitle
              : l10n.settingsCarpeaterDisabledSubtitle,
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
          title: Text(l10n.settingsTargetRepeater),
          subtitle: Text(_carpeaterRepeaterId ?? l10n.settingsNotSet),
          leading: const Icon(Icons.cell_tower),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () async {
            final result = await showSettingsTextInputDialog(
              context: context,
              title: l10n.settingsTargetRepeater,
              initialValue: _carpeaterRepeaterId ?? '',
              labelText: l10n.settingsRepeaterIdPrefix,
              hintText: l10n.settingsRepeaterIdHint,
              textCapitalization: TextCapitalization.characters,
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
          title: Text(l10n.settingsAdminPassword),
          subtitle: Text(
            _carpeaterPassword != null
                ? '•' * _carpeaterPassword!.length
                : l10n.settingsNotSet,
          ),
          leading: const Icon(Icons.lock),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () async {
            final result = await showSettingsTextInputDialog(
              context: context,
              title: l10n.settingsAdminPassword,
              initialValue: _carpeaterPassword ?? '',
              labelText: l10n.settingsPassword,
              hintText: l10n.settingsRepeaterAdminPasswordHint,
              obscureText: true,
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
          title: Text(l10n.settingsCycleInterval),
          subtitle: Text(l10n.settingsCycleIntervalSubtitle),
          trailing: DropdownButton<int>(
            value: _carpeaterInterval,
            items: [
              DropdownMenuItem(value: 0, child: Text(l10n.settingsNone)),
              const DropdownMenuItem(value: 5, child: Text('5s')),
              const DropdownMenuItem(value: 10, child: Text('10s')),
              const DropdownMenuItem(value: 15, child: Text('15s')),
              const DropdownMenuItem(value: 30, child: Text('30s')),
              const DropdownMenuItem(value: 60, child: Text('60s')),
              const DropdownMenuItem(value: 120, child: Text('2m')),
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
}
