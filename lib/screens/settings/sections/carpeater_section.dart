import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/models.dart';
import '../widgets/repeater_picker_dialog.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_text_input_dialog.dart';

class CarpeaterSettingsValues {
  const CarpeaterSettingsValues({
    required this.enabled,
    required this.repeaterId,
    required this.password,
    required this.interval,
    this.foundRepeaters = const [],
  });

  final bool enabled;
  final String? repeaterId;
  final String? password;
  final int interval;

  /// Previously found repeaters offered by the target repeater picker.
  final List<Repeater> foundRepeaters;
}

List<Widget> buildCarpeaterSettings(
  BuildContext context, {
  required CarpeaterSettingsValues values,
  required FutureOr<void> Function(bool value) onEnabledChanged,
  required FutureOr<void> Function(String? value) onRepeaterIdChanged,
  required FutureOr<void> Function(String? value) onPasswordChanged,
  required FutureOr<void> Function(int value) onIntervalChanged,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    SettingsSectionHeader(
      title: l10n.settingsSectionCarpeater,
      icon: Icons.cell_tower,
    ),
    SwitchListTile(
      title: Text(l10n.settingsEnableCarpeaterMode),
      subtitle: Text(
        values.enabled
            ? l10n.settingsCarpeaterEnabledSubtitle
            : l10n.settingsCarpeaterDisabledSubtitle,
      ),
      value: values.enabled,
      onChanged: onEnabledChanged,
    ),
    if (values.enabled) ...[
      ListTile(
        title: Text(l10n.settingsTargetRepeater),
        subtitle: _targetRepeaterSubtitle(l10n, values),
        leading: const Icon(Icons.cell_tower),
        trailing: const Icon(Icons.edit, size: 20),
        onTap: () async {
          final result = await showRepeaterPickerDialog(
            context: context,
            repeaters: values.foundRepeaters,
            selectedId: values.repeaterId,
          );
          if (result == null || !context.mounted) return;
          switch (result.action) {
            case RepeaterPickAction.select:
              await onRepeaterIdChanged(result.repeaterId);
            case RepeaterPickAction.clear:
              await onRepeaterIdChanged(null);
            case RepeaterPickAction.manualEntry:
              final manual = await _promptManualRepeaterId(
                context,
                l10n,
                values.repeaterId,
              );
              await onRepeaterIdChanged(manual);
          }
        },
      ),
      ListTile(
        title: Text(l10n.settingsAdminPassword),
        subtitle: Text(
          values.password != null
              ? '•' * values.password!.length
              : l10n.settingsNotSet,
        ),
        leading: const Icon(Icons.lock),
        trailing: const Icon(Icons.edit, size: 20),
        onTap: () async {
          final result = await showSettingsTextInputDialog(
            context: context,
            title: l10n.settingsAdminPassword,
            initialValue: values.password ?? '',
            labelText: l10n.settingsPassword,
            hintText: l10n.settingsRepeaterAdminPasswordHint,
            obscureText: true,
          );
          if (result != null) {
            await onPasswordChanged(result.isEmpty ? null : result);
          }
        },
      ),
      ListTile(
        title: Text(l10n.settingsCycleInterval),
        subtitle: Text(l10n.settingsCycleIntervalSubtitle),
        trailing: DropdownButton<int>(
          value: values.interval,
          items: [
            DropdownMenuItem(value: 0, child: Text(l10n.settingsNone)),
            const DropdownMenuItem(value: 5, child: Text('5s')),
            const DropdownMenuItem(value: 10, child: Text('10s')),
            const DropdownMenuItem(value: 15, child: Text('15s')),
            const DropdownMenuItem(value: 30, child: Text('30s')),
            const DropdownMenuItem(value: 60, child: Text('60s')),
            const DropdownMenuItem(value: 120, child: Text('2m')),
          ],
          onChanged: (value) {
            if (value != null) onIntervalChanged(value);
          },
        ),
      ),
    ],
  ];
}

Widget? _targetRepeaterSubtitle(
  AppLocalizations l10n,
  CarpeaterSettingsValues values,
) {
  final selectedId = values.repeaterId;
  if (selectedId == null || selectedId.isEmpty) {
    return Text(l10n.settingsNotSet);
  }
  final upperId = selectedId.toUpperCase();
  Repeater? repeater;
  for (final candidate in values.foundRepeaters) {
    if (candidate.id.toUpperCase() == upperId) {
      repeater = candidate;
      break;
    }
  }
  final name = repeater?.name;
  final displayId = displayRepeaterId(selectedId);
  if (name == null || name.isEmpty) {
    return Text(displayId);
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(name),
      Text(
        displayId,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    ],
  );
}

Future<String?> _promptManualRepeaterId(
  BuildContext context,
  AppLocalizations l10n,
  String? initialValue,
) async {
  final result = await showSettingsTextInputDialog(
    context: context,
    title: l10n.settingsTargetRepeater,
    initialValue: initialValue ?? '',
    labelText: l10n.settingsRepeaterIdPrefix,
    hintText: l10n.settingsRepeaterIdHint,
    textCapitalization: TextCapitalization.characters,
  );
  if (result == null) return null;
  final trimmed = result.trim();
  if (trimmed.isEmpty) return null;
  return trimmed.toUpperCase();
}
