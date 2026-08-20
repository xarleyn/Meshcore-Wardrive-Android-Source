import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/settings_service.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_text_input_dialog.dart';

class AppDeviceSettingsValues {
  const AppDeviceSettingsValues({
    required this.deviceName,
    required this.keepScreenOn,
    required this.batterySaverEnabled,
    required this.lockRotationNorth,
    required this.currentLocationMarkerStyle,
    required this.interfaceThemeDescription,
    required this.mapThemeDescription,
    required this.localePreferenceDescription,
    required this.loraConnected,
    required this.repeaterCount,
    required this.colorMode,
    required this.distanceUnit,
    required this.fuelUnit,
    required this.colorBlindMode,
  });

  final Future<String?> deviceName;
  final bool keepScreenOn;
  final bool batterySaverEnabled;
  final bool lockRotationNorth;
  final CurrentLocationMarkerStyle currentLocationMarkerStyle;
  final String interfaceThemeDescription;
  final String mapThemeDescription;
  final String localePreferenceDescription;
  final bool loraConnected;
  final int repeaterCount;
  final String colorMode;
  final String distanceUnit;
  final String fuelUnit;
  final String colorBlindMode;
}

List<Widget> buildAppDeviceSettings(
  BuildContext context, {
  required AppDeviceSettingsValues values,
  required FutureOr<void> Function(String? value) onDeviceNameChanged,
  required FutureOr<void> Function(bool value) onKeepScreenOnChanged,
  required FutureOr<void> Function(bool value) onBatterySaverChanged,
  required FutureOr<void> Function(bool value) onLockRotationNorthChanged,
  required FutureOr<void> Function(CurrentLocationMarkerStyle value)
  onCurrentLocationMarkerStyleChanged,
  required FutureOr<void> Function() onCalibrateCompass,
  required FutureOr<void> Function() onSelectInterfaceTheme,
  required FutureOr<void> Function() onSelectMapTheme,
  required FutureOr<void> Function() onSelectLanguage,
  required FutureOr<void> Function() onScanForRepeaters,
  required FutureOr<void> Function() onRefreshContacts,
  required FutureOr<void> Function(String value) onColorModeChanged,
  required FutureOr<void> Function(String value) onDistanceUnitChanged,
  required FutureOr<void> Function(String value) onFuelUnitChanged,
  required FutureOr<void> Function(String value) onColorBlindModeChanged,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    SettingsSectionHeader(
      title: l10n.settingsSectionAppDevice,
      icon: Icons.tune,
    ),
    ListTile(
      title: Text(l10n.settingsDeviceName),
      subtitle: FutureBuilder<String?>(
        future: values.deviceName,
        builder: (context, snap) =>
            Text(snap.data ?? l10n.settingsDeviceNameNotSet),
      ),
      leading: const Icon(Icons.badge),
      trailing: const Icon(Icons.edit, size: 20),
      onTap: () async {
        final current = await values.deviceName;
        if (!context.mounted) return;
        final result = await showSettingsTextInputDialog(
          context: context,
          title: l10n.settingsDeviceName,
          initialValue: current ?? '',
          labelText: l10n.settingsDeviceNameLabel,
          hintText: l10n.settingsDeviceNameHint,
        );
        if (result != null) {
          await onDeviceNameChanged(result.isEmpty ? null : result);
        }
      },
    ),
    const Divider(),
    SwitchListTile(
      title: Text(l10n.settingsKeepScreenOn),
      subtitle: Text(l10n.settingsKeepScreenOnSubtitle),
      secondary: const Icon(Icons.screen_lock_portrait),
      value: values.keepScreenOn,
      onChanged: onKeepScreenOnChanged,
    ),
    SwitchListTile(
      title: Text(l10n.settingsBatterySaver),
      subtitle: Text(l10n.settingsBatterySaverSubtitle),
      secondary: const Icon(Icons.battery_saver),
      value: values.batterySaverEnabled,
      onChanged: onBatterySaverChanged,
    ),
    SwitchListTile(
      title: Text(l10n.settingsLockMapRotation),
      subtitle: Text(l10n.settingsLockMapRotationSubtitle),
      value: values.lockRotationNorth,
      onChanged: onLockRotationNorthChanged,
    ),
    ListTile(
      title: Text(l10n.settingsCurrentLocationMarker),
      subtitle: Text(l10n.settingsCurrentLocationMarkerSubtitle),
      trailing: DropdownButton<CurrentLocationMarkerStyle>(
        value: values.currentLocationMarkerStyle,
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
        onChanged: (value) {
          if (value != null) onCurrentLocationMarkerStyleChanged(value);
        },
      ),
    ),
    ListTile(
      title: Text(l10n.settingsCalibrateCompass),
      subtitle: Text(l10n.settingsCalibrateCompassSubtitle),
      leading: const Icon(Icons.explore),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onCalibrateCompass(),
    ),
    ListTile(
      title: Text(l10n.settingsInterfaceTheme),
      subtitle: Text(values.interfaceThemeDescription),
      trailing: const Icon(Icons.brightness_6),
      onTap: () => onSelectInterfaceTheme(),
    ),
    ListTile(
      title: Text(l10n.settingsMapTheme),
      subtitle: Text(values.mapThemeDescription),
      trailing: const Icon(Icons.map_outlined),
      onTap: () => onSelectMapTheme(),
    ),
    ListTile(
      title: Text(l10n.language),
      subtitle: Text(values.localePreferenceDescription),
      trailing: const Icon(Icons.language),
      onTap: () => onSelectLanguage(),
    ),
    if (values.loraConnected)
      ListTile(
        title: Text(l10n.settingsScanForRepeaters),
        subtitle: Text(
          values.repeaterCount == 0
              ? l10n.settingsScanFindNearby
              : l10n.settingsRepeatersFound(values.repeaterCount),
        ),
        leading: const Icon(Icons.cell_tower),
        trailing: const Icon(Icons.search),
        onTap: () => onScanForRepeaters(),
      ),
    if (values.loraConnected)
      ListTile(
        title: Text(l10n.settingsRefreshContactList),
        subtitle: Text(l10n.settingsRefreshContactListSubtitle),
        leading: const Icon(Icons.refresh),
        onTap: () => onRefreshContacts(),
      ),
    ListTile(
      title: Text(l10n.settingsColorMode),
      trailing: DropdownButton<String>(
        value: values.colorMode,
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
        onChanged: (value) {
          if (value != null) onColorModeChanged(value);
        },
      ),
    ),
    ListTile(
      title: Text(l10n.settingsDistanceUnit),
      trailing: DropdownButton<String>(
        value: values.distanceUnit,
        items: [
          DropdownMenuItem(value: 'miles', child: Text(l10n.settingsMiles)),
          DropdownMenuItem(value: 'km', child: Text(l10n.settingsKilometers)),
        ],
        onChanged: (value) {
          if (value != null) onDistanceUnitChanged(value);
        },
      ),
    ),
    ListTile(
      title: Text(l10n.settingsFuelUnit),
      trailing: DropdownButton<String>(
        value: values.fuelUnit,
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
        onChanged: (value) {
          if (value != null) onFuelUnitChanged(value);
        },
      ),
    ),
    ListTile(
      title: Text(l10n.settingsColorBlindMode),
      trailing: DropdownButton<String>(
        value: values.colorBlindMode,
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
        onChanged: (value) {
          if (value != null) onColorBlindModeChanged(value);
        },
      ),
    ),
  ];
}
