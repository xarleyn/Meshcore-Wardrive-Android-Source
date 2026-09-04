import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'widgets/settings_text_input_dialog.dart';

class NullableTextSettingResult {
  const NullableTextSettingResult(this.value);

  final String? value;
}

String pingIntervalDescription(BuildContext context, double intervalMeters) {
  final l10n = AppLocalizations.of(context);
  if (intervalMeters < 100) {
    return l10n.settingsPingIntervalMetersFrequent(intervalMeters.toInt());
  }
  if (intervalMeters < 1000) {
    return l10n.settingsPingIntervalMeters(intervalMeters.toInt());
  }
  final miles = (intervalMeters / 1609.34).toStringAsFixed(1);
  return l10n.settingsPingIntervalMiles(miles, intervalMeters.toInt());
}

Future<double?> showPingIntervalDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  return showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.settingsPingDistance),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.settingsPingIntervalPrompt),
          const SizedBox(height: 16),
          ListTile(
            title: Text(l10n.settingsPingFrequent),
            subtitle: Text(l10n.settingsPingFrequentSubtitle),
            onTap: () => Navigator.pop(context, 50.0),
          ),
          ListTile(
            title: Text(l10n.settingsPingNormal),
            subtitle: Text(l10n.settingsPingNormalSubtitle),
            onTap: () => Navigator.pop(context, 200.0),
          ),
          ListTile(
            title: Text(l10n.settingsPingSparse),
            subtitle: Text(l10n.settingsPingSparseSubtitle),
            onTap: () => Navigator.pop(context, 805.0),
          ),
          ListTile(
            title: Text(l10n.settingsPingVerySparse),
            subtitle: Text(l10n.settingsPingVerySparseSubtitle),
            onTap: () => Navigator.pop(context, 1609.0),
          ),
        ],
      ),
    ),
  );
}

String coverageResolutionDescription(BuildContext context, int precision) {
  final l10n = AppLocalizations.of(context);
  return switch (precision) {
    4 => l10n.settingsCoverageRegionalDesc,
    5 => l10n.settingsCoverageCityDesc,
    6 => l10n.settingsCoverageNeighborhoodDesc,
    7 => l10n.settingsCoverageStreetDesc,
    8 => l10n.settingsCoverageBuildingDesc,
    _ => l10n.settingsUnknown,
  };
}

Future<int?> showCoverageResolutionDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.settingsCoverageResolution),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.settingsCoverageResolutionPrompt),
          const SizedBox(height: 16),
          ListTile(
            title: Text(l10n.settingsCoverageRegional),
            subtitle: Text(l10n.settingsCoverageRegionalSubtitle),
            onTap: () => Navigator.pop(context, 4),
          ),
          ListTile(
            title: Text(l10n.settingsCoverageCity),
            subtitle: Text(l10n.settingsCoverageCitySubtitle),
            onTap: () => Navigator.pop(context, 5),
          ),
          ListTile(
            title: Text(l10n.settingsCoverageNeighborhood),
            subtitle: Text(l10n.settingsCoverageNeighborhoodSubtitle),
            onTap: () => Navigator.pop(context, 6),
          ),
          ListTile(
            title: Text(l10n.settingsCoverageStreet),
            subtitle: Text(l10n.settingsCoverageStreetSubtitle),
            onTap: () => Navigator.pop(context, 7),
          ),
          ListTile(
            title: Text(l10n.settingsCoverageBuilding),
            subtitle: Text(l10n.settingsCoverageBuildingSubtitle),
            onTap: () => Navigator.pop(context, 8),
          ),
        ],
      ),
    ),
  );
}

Future<NullableTextSettingResult?> showIgnoredRepeaterDialog(
  BuildContext context, {
  required String? currentValue,
}) async {
  final l10n = AppLocalizations.of(context);
  final input = await showSettingsTextInputDialog(
    context: context,
    title: l10n.settingsIgnoreRepeaters,
    initialValue: currentValue ?? '',
    labelText: l10n.settingsRepeaterPrefixes,
    hintText: l10n.settingsIgnoreRepeaterHint,
    description: l10n.settingsIgnoreRepeaterDescription,
    textCapitalization: TextCapitalization.characters,
    maxLines: 2,
  );
  if (input == null) return null;
  final value = input.trim();
  return NullableTextSettingResult(value.isEmpty ? null : value);
}

Future<NullableTextSettingResult?> showIncludedRepeaterDialog(
  BuildContext context, {
  required String? currentValue,
}) async {
  final l10n = AppLocalizations.of(context);
  final input = await showSettingsTextInputDialog(
    context: context,
    title: l10n.settingsIncludeOnlyRepeaters,
    initialValue: currentValue ?? '',
    labelText: l10n.settingsRepeaterPrefixes,
    hintText: l10n.settingsIncludeOnlyHint,
    description: l10n.settingsIncludeOnlyDescription,
    textCapitalization: TextCapitalization.characters,
    maxLines: 2,
  );
  if (input == null) return null;
  final value = input.trim();
  return NullableTextSettingResult(value.isEmpty ? null : value);
}
