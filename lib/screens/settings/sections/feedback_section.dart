part of '../../map_screen.dart';

extension _FeedbackSettingsSection on _MapScreenState {
  List<Widget> _buildFeedbackSettings(StateSetter setModalState) {
    final l10n = AppLocalizations.of(context);
    return [
      SettingsSectionHeader(
        title: l10n.settingsSectionFeedback,
        icon: Icons.notifications_outlined,
      ),
      SwitchListTile(
        title: Text(l10n.settingsSoundFeedback),
        subtitle: Text(l10n.settingsSoundFeedbackSubtitle),
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
        title: Text(l10n.settingsVibrationFeedback),
        subtitle: Text(l10n.settingsVibrationFeedbackSubtitle),
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
        title: Text(l10n.settingsDeadZoneAlerts),
        subtitle: Text(l10n.settingsDeadZoneAlertsSubtitle),
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
        title: Text(l10n.settingsNewRepeaterAlerts),
        subtitle: Text(l10n.settingsNewRepeaterAlertsSubtitle),
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
}
