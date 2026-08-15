part of '../../map_screen.dart';

extension _FeedbackSettingsSection on _MapScreenState {
  List<Widget> _buildFeedbackSettings(StateSetter setModalState) => [
    const SettingsSectionHeader(
      title: 'Feedback & alerts',
      icon: Icons.notifications_outlined,
    ),
    SwitchListTile(
      title: const Text('Sound Feedback'),
      subtitle: const Text('Play tones on ping results'),
      value: _soundEnabled,
      onChanged: (value) async {
        _updateMapState(() {
          _soundEnabled = value;
        });
        setModalState(() {});
        await _settingsService.setSoundEnabled(value);
        SoundService().setEnabled(value);
      },
    ),
    SwitchListTile(
      title: const Text('Vibration Feedback'),
      subtitle: const Text('Haptic feedback on ping results'),
      value: _vibrationEnabled,
      onChanged: (value) async {
        _updateMapState(() {
          _vibrationEnabled = value;
        });
        setModalState(() {});
        await _settingsService.setVibrationEnabled(value);
        SoundService().setVibrationEnabled(value);
      },
    ),
    SwitchListTile(
      title: const Text('Dead Zone Alerts'),
      subtitle: const Text('Notify when entering a known dead zone'),
      value: _deadZoneAlertsEnabled,
      onChanged: (value) async {
        _updateMapState(() {
          _deadZoneAlertsEnabled = value;
        });
        setModalState(() {});
        await _settingsService.setDeadZoneAlertsEnabled(value);
      },
    ),
    SwitchListTile(
      title: const Text('New Repeater Alerts'),
      subtitle: const Text(
        'Notify when a never-before-seen repeater is discovered',
      ),
      value: _newRepeaterAlertsEnabled,
      onChanged: (value) async {
        _updateMapState(() {
          _newRepeaterAlertsEnabled = value;
        });
        setModalState(() {});
        await _settingsService.setNewRepeaterAlertsEnabled(value);
        _locationService.loraCompanion.setNewRepeaterAlertsEnabled(value);
      },
    ),
  ];
}
