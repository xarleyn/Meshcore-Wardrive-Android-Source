import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../widgets/settings_section_header.dart';

class FeedbackSettingsValues {
  const FeedbackSettingsValues({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.deadZoneAlertsEnabled,
    required this.newRepeaterAlertsEnabled,
    required this.linkLossAlertsEnabled,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool deadZoneAlertsEnabled;
  final bool newRepeaterAlertsEnabled;
  final bool linkLossAlertsEnabled;
}

List<Widget> buildFeedbackSettings(
  BuildContext context, {
  required FeedbackSettingsValues values,
  required ValueChanged<bool> onSoundChanged,
  required ValueChanged<bool> onVibrationChanged,
  required ValueChanged<bool> onDeadZoneAlertsChanged,
  required ValueChanged<bool> onNewRepeaterAlertsChanged,
  required ValueChanged<bool> onLinkLossAlertsChanged,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    SettingsSectionHeader(
      title: l10n.settingsSectionFeedback,
      icon: Icons.notifications_outlined,
    ),
    SwitchListTile(
      title: Text(l10n.settingsSoundFeedback),
      subtitle: Text(l10n.settingsSoundFeedbackSubtitle),
      value: values.soundEnabled,
      onChanged: onSoundChanged,
    ),
    SwitchListTile(
      title: Text(l10n.settingsVibrationFeedback),
      subtitle: Text(l10n.settingsVibrationFeedbackSubtitle),
      value: values.vibrationEnabled,
      onChanged: onVibrationChanged,
    ),
    SwitchListTile(
      title: Text(l10n.settingsDeadZoneAlerts),
      subtitle: Text(l10n.settingsDeadZoneAlertsSubtitle),
      value: values.deadZoneAlertsEnabled,
      onChanged: onDeadZoneAlertsChanged,
    ),
    SwitchListTile(
      title: Text(l10n.settingsNewRepeaterAlerts),
      subtitle: Text(l10n.settingsNewRepeaterAlertsSubtitle),
      value: values.newRepeaterAlertsEnabled,
      onChanged: onNewRepeaterAlertsChanged,
    ),
    SwitchListTile(
      title: Text(l10n.settingsLinkLossAlerts),
      subtitle: Text(l10n.settingsLinkLossAlertsSubtitle),
      value: values.linkLossAlertsEnabled,
      onChanged: onLinkLossAlertsChanged,
    ),
  ];
}
