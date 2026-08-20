import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../utils/discovery_timeout_options.dart';
import '../widgets/settings_section_header.dart';

class DiscoverySettingsValues {
  const DiscoverySettingsValues({
    required this.timeoutSeconds,
    required this.thoroughResponseCollection,
    required this.ignoredRepeaterPrefix,
    required this.includeOnlyRepeaters,
    required this.filterEdgesByWhitelist,
    required this.pingMode,
    required this.pingTimeInterval,
    required this.pingIntervalDescription,
    required this.coverageResolutionDescription,
  });

  final int timeoutSeconds;
  final bool thoroughResponseCollection;
  final String? ignoredRepeaterPrefix;
  final String? includeOnlyRepeaters;
  final bool filterEdgesByWhitelist;
  final String pingMode;
  final int pingTimeInterval;
  final String pingIntervalDescription;
  final String coverageResolutionDescription;
}

List<Widget> buildDiscoverySettings(
  BuildContext context, {
  required DiscoverySettingsValues values,
  required FutureOr<void> Function(int value) onTimeoutChanged,
  required FutureOr<void> Function(bool value) onThoroughChanged,
  required VoidCallback onEditIgnoredRepeaters,
  required VoidCallback onEditIncludedRepeaters,
  required FutureOr<void> Function(bool value) onFilterEdgesChanged,
  required FutureOr<void> Function(String value) onPingModeChanged,
  required VoidCallback onEditPingInterval,
  required FutureOr<void> Function(int value) onPingTimeIntervalChanged,
  required VoidCallback onEditCoverageResolution,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    SettingsSectionHeader(
      title: l10n.settingsSectionDiscovery,
      icon: Icons.radar,
    ),
    ListTile(
      title: Text(l10n.settingsDiscoveryTimeout),
      subtitle: Text(l10n.settingsDiscoveryTimeoutSubtitle),
      trailing: DiscoveryTimeoutDropdown(
        value: values.timeoutSeconds,
        isDense: false,
        itemStyle: null,
        onChanged: onTimeoutChanged,
      ),
    ),
    SwitchListTile(
      title: Text(l10n.settingsThoroughResponseCollection),
      subtitle: Text(
        values.thoroughResponseCollection
            ? l10n.settingsThoroughOn
            : l10n.settingsThoroughOff,
      ),
      value: values.thoroughResponseCollection,
      onChanged: onThoroughChanged,
    ),
    ListTile(
      title: Text(l10n.settingsIgnoreRepeaters),
      subtitle: Text(
        values.ignoredRepeaterPrefix?.isNotEmpty ?? false
            ? l10n.settingsIgnoringPrefix(values.ignoredRepeaterPrefix!)
            : l10n.settingsNotFiltering,
      ),
      trailing: const Icon(Icons.edit),
      onTap: onEditIgnoredRepeaters,
    ),
    ListTile(
      title: Text(l10n.settingsIncludeOnlyRepeaters),
      subtitle: Text(
        values.includeOnlyRepeaters?.isNotEmpty ?? false
            ? l10n.settingsWhitelistPrefix(values.includeOnlyRepeaters!)
            : l10n.settingsShowAllRepeaters,
      ),
      trailing: const Icon(Icons.edit),
      onTap: onEditIncludedRepeaters,
    ),
    SwitchListTile(
      title: Text(l10n.settingsApplyWhitelistToEdges),
      subtitle: Text(l10n.settingsApplyWhitelistToEdgesSubtitle),
      value: values.filterEdgesByWhitelist,
      onChanged: onFilterEdgesChanged,
    ),
    ListTile(
      title: Text(l10n.settingsPingMode),
      trailing: DropdownButton<String>(
        value: values.pingMode,
        items: [
          DropdownMenuItem(
            value: 'distance',
            child: Text(l10n.settingsPingModeDistance),
          ),
          DropdownMenuItem(
            value: 'time',
            child: Text(l10n.settingsPingModeTime),
          ),
          DropdownMenuItem(
            value: 'both',
            child: Text(l10n.settingsPingModeBoth),
          ),
        ],
        onChanged: (value) {
          if (value != null) onPingModeChanged(value);
        },
      ),
    ),
    if (values.pingMode != 'time')
      ListTile(
        title: Text(l10n.settingsPingDistance),
        subtitle: Text(values.pingIntervalDescription),
        trailing: const Icon(Icons.tune),
        onTap: onEditPingInterval,
      ),
    if (values.pingMode != 'distance')
      ListTile(
        title: Text(l10n.settingsPingTimeInterval),
        trailing: DropdownButton<int>(
          value: values.pingTimeInterval,
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
          onChanged: (value) {
            if (value != null) onPingTimeIntervalChanged(value);
          },
        ),
      ),
    ListTile(
      title: Text(l10n.settingsCoverageResolution),
      subtitle: Text(values.coverageResolutionDescription),
      trailing: const Icon(Icons.grid_on),
      onTap: onEditCoverageResolution,
    ),
  ];
}
