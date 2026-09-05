import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/impossible_zone.dart';
import '../../../models/location_quality_settings.dart';
import '../../map/dialogs/marker_dialogs.dart';
import '../../../widgets/confirm_dialog.dart';
import '../settings_screen.dart';

Future<void> showLocationQualitySettings(
  BuildContext context, {
  required LocationQualitySettings Function() settings,
  required List<ImpossibleZone> Function() zones,
  required LatLng Function() newZoneCenter,
  required Future<void> Function(LocationQualitySettings value)
  onSettingsChanged,
  required Future<void> Function() onResetSettings,
  required Future<void> Function(ImpossibleZoneDraft draft) onAddZone,
  required Future<void> Function(int id) onDeleteZone,
  required Future<void> Function() onClearZones,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => SettingsScreen.category(
        title: AppLocalizations.of(context).settingsLocationQualityFilters,
        contentBuilder: (context, setPageState, scrollController) => ListView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: _buildLocationQualitySettings(
            context,
            settings: settings(),
            zones: zones(),
            newZoneCenter: newZoneCenter,
            onSettingsChanged: (value) async {
              await onSettingsChanged(value);
              setPageState(() {});
            },
            onResetSettings: () async {
              await onResetSettings();
              setPageState(() {});
            },
            onAddZone: (draft) async {
              await onAddZone(draft);
              setPageState(() {});
            },
            onDeleteZone: (id) async {
              await onDeleteZone(id);
              setPageState(() {});
            },
            onClearZones: () async {
              await onClearZones();
              setPageState(() {});
            },
          ),
        ),
      ),
    ),
  );
}

List<Widget> _buildLocationQualitySettings(
  BuildContext context, {
  required LocationQualitySettings settings,
  required List<ImpossibleZone> zones,
  required LatLng Function() newZoneCenter,
  required Future<void> Function(LocationQualitySettings value)
  onSettingsChanged,
  required Future<void> Function() onResetSettings,
  required Future<void> Function(ImpossibleZoneDraft draft) onAddZone,
  required Future<void> Function(int id) onDeleteZone,
  required Future<void> Function() onClearZones,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    SettingsSectionHeader(
      title: l10n.settingsSectionThresholds,
      icon: Icons.gps_fixed,
    ),
    ListTile(
      title: Text(l10n.settingsMaxHorizontalError),
      subtitle: Text(l10n.settingsMaxHorizontalErrorSubtitle),
      trailing: Text('${_formatValue(settings.maxHorizontalAccuracyMeters)} m'),
      onTap: () => _editValue(
        context,
        title: l10n.settingsMaxHorizontalError,
        description: l10n.settingsMaxHorizontalErrorDescription,
        unit: 'm',
        displayedValue: settings.maxHorizontalAccuracyMeters,
        onSaved: (value) => onSettingsChanged(
          settings.copyWith(maxHorizontalAccuracyMeters: value),
        ),
      ),
    ),
    ListTile(
      title: Text(l10n.settingsAirborneAltitude),
      subtitle: Text(l10n.settingsAirborneAltitudeSubtitle),
      trailing: Text('${_formatValue(settings.airborneAltitudeMeters)} m'),
      onTap: () => _editValue(
        context,
        title: l10n.settingsAirborneAltitude,
        description: l10n.settingsAirborneAltitudeDescription,
        unit: 'm',
        displayedValue: settings.airborneAltitudeMeters,
        onSaved: (value) =>
            onSettingsChanged(settings.copyWith(airborneAltitudeMeters: value)),
      ),
    ),
    ListTile(
      title: Text(l10n.settingsAirborneSpeed),
      subtitle: Text(l10n.settingsAirborneSpeedSubtitle),
      trailing: Text(
        '${_formatValue(settings.airborneSpeedMetersPerSecond * 3.6)} km/h',
      ),
      onTap: () => _editValue(
        context,
        title: l10n.settingsAirborneSpeed,
        description: l10n.settingsAirborneSpeedDescription,
        unit: 'km/h',
        displayedValue: settings.airborneSpeedMetersPerSecond * 3.6,
        onSaved: (value) => onSettingsChanged(
          settings.copyWith(airborneSpeedMetersPerSecond: value / 3.6),
        ),
      ),
    ),
    ListTile(
      title: Text(l10n.settingsMaxWardriveSpeed),
      subtitle: Text(l10n.settingsMaxWardriveSpeedSubtitle),
      trailing: Text(
        '${_formatValue(settings.maxWardriveSpeedMetersPerSecond * 3.6)} km/h',
      ),
      onTap: () => _editValue(
        context,
        title: l10n.settingsMaxWardriveSpeed,
        description: l10n.settingsMaxWardriveSpeedDescription,
        unit: 'km/h',
        displayedValue: settings.maxWardriveSpeedMetersPerSecond * 3.6,
        onSaved: (value) => onSettingsChanged(
          settings.copyWith(maxWardriveSpeedMetersPerSecond: value / 3.6),
        ),
      ),
    ),
    Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 8),
        child: TextButton.icon(
          onPressed: onResetSettings,
          icon: const Icon(Icons.restore),
          label: Text(l10n.settingsRestoreDefaults),
        ),
      ),
    ),
    SettingsSectionHeader(
      title: l10n.settingsSectionAutoPingPause,
      icon: Icons.notifications_paused_outlined,
    ),
    SwitchListTile(
      title: Text(l10n.settingsPingPauseOnBadFixes),
      subtitle: Text(l10n.settingsPingPauseOnBadFixesSubtitle),
      value: settings.pausePingsOnBadFixes,
      onChanged: (value) =>
          onSettingsChanged(settings.copyWith(pausePingsOnBadFixes: value)),
    ),
    if (settings.pausePingsOnBadFixes)
      ListTile(
        title: Text(l10n.settingsPingPauseBadFixCount),
        subtitle: Text(l10n.settingsPingPauseBadFixCountSubtitle),
        trailing: Text('${settings.pingPauseBadFixCount}'),
        onTap: () => _editIntValue(
          context,
          title: l10n.settingsPingPauseBadFixCount,
          description: l10n.settingsPingPauseBadFixCountDescription,
          displayedValue: settings.pingPauseBadFixCount,
          min: LocationQualitySettings.minPingPauseBadFixCount,
          max: LocationQualitySettings.maxPingPauseBadFixCount,
          onSaved: (value) =>
              onSettingsChanged(settings.copyWith(pingPauseBadFixCount: value)),
        ),
      ),
    SettingsSectionHeader(
      title: l10n.settingsSectionImpossibleZones,
      icon: Icons.block_outlined,
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        l10n.settingsImpossibleZonesBlurb,
        style: const TextStyle(fontSize: 13),
      ),
    ),
    ListTile(
      title: Text(l10n.settingsAddImpossibleZone),
      subtitle: Text(
        zones.isEmpty
            ? l10n.settingsImpossibleZoneEmptySubtitle
            : l10n.settingsImpossibleZoneCount(zones.length),
      ),
      leading: const Icon(Icons.add_location_alt_outlined),
      onTap: () async {
        final draft = await showDialog<ImpossibleZoneDraft>(
          context: context,
          builder: (context) =>
              AddImpossibleZoneDialog(center: newZoneCenter()),
        );
        if (draft != null) await onAddZone(draft);
      },
    ),
    for (final zone in zones)
      ListTile(
        title: Text(
          zone.label?.isNotEmpty ?? false
              ? zone.label!
              : l10n.settingsUnnamedZone,
        ),
        subtitle: Text(
          '${zone.lat.toStringAsFixed(5)}, ${zone.lon.toStringAsFixed(5)} '
          '\u00b7 ${zone.radiusMeters.toStringAsFixed(0)} m',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.settingsDeleteZoneTooltip,
          onPressed: zone.id == null ? null : () => onDeleteZone(zone.id!),
        ),
      ),
    if (zones.isNotEmpty)
      ListTile(
        title: Text(l10n.settingsClearImpossibleZones),
        subtitle: Text(l10n.settingsRemoveAllZones(zones.length)),
        leading: const Icon(Icons.delete_outline, color: Colors.red),
        onTap: () async {
          final confirmed = await showConfirmDialog(
            context,
            title: l10n.settingsClearImpossibleZones,
            content: l10n.settingsClearImpossibleZonesConfirm,
            confirmLabel: l10n.settingsClear,
            destructive: true,
          );
          if (confirmed == true) await onClearZones();
        },
      ),
  ];
}

Future<void> _editValue(
  BuildContext context, {
  required String title,
  required String description,
  required String unit,
  required double displayedValue,
  required Future<void> Function(double value) onSaved,
}) async {
  final l10n = AppLocalizations.of(context);
  final input = await showSettingsTextInputDialog(
    context: context,
    title: title,
    initialValue: _formatValue(displayedValue),
    labelText: title,
    description: description,
    suffixText: unit,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (text) {
      final parsed = double.tryParse((text ?? '').trim().replaceAll(',', '.'));
      if (parsed == null || !parsed.isFinite || parsed <= 0) {
        return l10n.settingsEnterNumberGreaterThanZero;
      }
      return null;
    },
  );
  if (input == null || !context.mounted) return;
  await onSaved(double.parse(input.trim().replaceAll(',', '.')));
}

Future<void> _editIntValue(
  BuildContext context, {
  required String title,
  required String description,
  required int displayedValue,
  required int min,
  required int max,
  required Future<void> Function(int value) onSaved,
}) async {
  final l10n = AppLocalizations.of(context);
  final input = await showSettingsTextInputDialog(
    context: context,
    title: title,
    initialValue: '$displayedValue',
    labelText: title,
    description: description,
    keyboardType: const TextInputType.numberWithOptions(),
    validator: (text) {
      final parsed = int.tryParse((text ?? '').trim());
      if (parsed == null || parsed < min || parsed > max) {
        return l10n.settingsEnterBadFixCount(min, max);
      }
      return null;
    },
  );
  if (input == null || !context.mounted) return;
  await onSaved(int.parse(input.trim()));
}

String _formatValue(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
