import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../ducting_forecast_screen.dart';
import '../widgets/settings_section_header.dart';

class LocationSettingsValues {
  const LocationSettingsValues({
    required this.beaconDbWifiPositioning,
    required this.showRadioPosition,
    required this.showDucting,
  });

  final bool beaconDbWifiPositioning;
  final bool showRadioPosition;
  final bool showDucting;
}

List<Widget> buildLocationSettings(
  BuildContext context, {
  required LocationSettingsValues values,
  required FutureOr<void> Function(bool value) onBeaconDbChanged,
  required VoidCallback onOpenLocationQuality,
  required FutureOr<void> Function(bool value) onRadioPositionChanged,
  required FutureOr<void> Function(bool value) onDuctingChanged,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    SettingsSectionHeader(
      title: l10n.settingsSectionLocation,
      icon: Icons.my_location,
    ),
    SwitchListTile(
      title: Text(l10n.settingsBeaconDbWifi),
      subtitle: Text(l10n.settingsBeaconDbWifiSubtitle),
      value: values.beaconDbWifiPositioning,
      onChanged: onBeaconDbChanged,
    ),
    ListTile(
      leading: const Icon(Icons.gps_fixed),
      title: Text(l10n.settingsLocationQualityFilters),
      subtitle: Text(l10n.settingsLocationQualityFiltersSubtitle),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onOpenLocationQuality,
    ),
    SwitchListTile(
      title: Text(l10n.settingsShowApproximatePosition),
      subtitle: Text(l10n.settingsShowApproximatePositionSubtitle),
      value: values.showRadioPosition,
      onChanged: onRadioPositionChanged,
    ),
    ListTile(
      title: Text(l10n.settingsDuctingForecast),
      subtitle: Text(l10n.settingsDuctingForecastSubtitle),
      leading: const Icon(Icons.cloud),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const DuctingForecastScreen(),
          ),
        );
      },
    ),
    SwitchListTile(
      title: Text(l10n.settingsAtmosphericDucting),
      subtitle: Text(l10n.settingsAtmosphericDuctingSubtitle),
      value: values.showDucting,
      onChanged: onDuctingChanged,
    ),
  ];
}
