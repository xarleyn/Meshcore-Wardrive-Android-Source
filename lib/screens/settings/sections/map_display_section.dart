import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../widgets/settings_section_header.dart';

enum MapDisplaySetting {
  coverage,
  mapLod,
  samples,
  edges,
  repeaters,
  gpsSamples,
  successfulOnly,
  optimisticDisplay,
  routeTrail,
  communityCoverage,
  heatmap,
  predictionRings,
}

class MapDisplaySettingsValues {
  const MapDisplaySettingsValues({
    required this.showCoverage,
    required this.mapLodEnabled,
    required this.showSamples,
    required this.showEdges,
    required this.showRepeaters,
    required this.showGpsSamples,
    required this.showSuccessfulOnly,
    required this.optimisticDisplay,
    required this.showRouteTrail,
    required this.communityCoverageAvailable,
    required this.showCommunityCoverage,
    required this.showHeatmap,
    required this.showPredictionRings,
  });

  final bool showCoverage;
  final bool mapLodEnabled;
  final bool showSamples;
  final bool showEdges;
  final bool showRepeaters;
  final bool showGpsSamples;
  final bool showSuccessfulOnly;
  final bool optimisticDisplay;
  final bool showRouteTrail;
  final bool communityCoverageAvailable;
  final bool showCommunityCoverage;
  final bool showHeatmap;
  final bool showPredictionRings;
}

List<Widget> buildMapDisplaySettings(
  BuildContext context, {
  required MapDisplaySettingsValues values,
  required FutureOr<void> Function(MapDisplaySetting setting, bool value)
  onChanged,
  required FutureOr<void> Function() onClearCommunityCoverage,
}) {
  final l10n = AppLocalizations.of(context);
  return [
    SettingsSectionHeader(
      title: l10n.settingsSectionMapDisplay,
      icon: Icons.map_outlined,
    ),
    SwitchListTile(
      title: Text(l10n.settingsShowCoverageBoxes),
      value: values.showCoverage,
      onChanged: (value) => onChanged(MapDisplaySetting.coverage, value),
    ),
    SwitchListTile(
      title: Text(l10n.settingsSimplifyMapAtLowZoom),
      subtitle: Text(l10n.settingsSimplifyMapAtLowZoomSubtitle),
      value: values.mapLodEnabled,
      onChanged: (value) => onChanged(MapDisplaySetting.mapLod, value),
    ),
    SwitchListTile(
      title: Text(l10n.settingsShowSamples),
      value: values.showSamples,
      onChanged: (value) => onChanged(MapDisplaySetting.samples, value),
    ),
    SwitchListTile(
      title: Text(l10n.settingsShowEdges),
      value: values.showEdges,
      onChanged: (value) => onChanged(MapDisplaySetting.edges, value),
    ),
    SwitchListTile(
      title: Text(l10n.settingsShowRepeaters),
      value: values.showRepeaters,
      onChanged: (value) => onChanged(MapDisplaySetting.repeaters, value),
    ),
    SwitchListTile(
      title: Text(l10n.settingsShowGpsSamples),
      subtitle: Text(l10n.settingsShowGpsSamplesSubtitle),
      value: values.showGpsSamples,
      onChanged: (value) => onChanged(MapDisplaySetting.gpsSamples, value),
    ),
    SwitchListTile(
      title: Text(l10n.settingsShowSuccessfulPingsOnly),
      subtitle: Text(l10n.settingsShowSuccessfulPingsOnlySubtitle),
      value: values.showSuccessfulOnly,
      onChanged: (value) => onChanged(MapDisplaySetting.successfulOnly, value),
    ),
    SwitchListTile(
      title: Text(l10n.settingsOptimisticDisplay),
      subtitle: Text(l10n.settingsOptimisticDisplaySubtitle),
      value: values.optimisticDisplay,
      onChanged: (value) =>
          onChanged(MapDisplaySetting.optimisticDisplay, value),
    ),
    SwitchListTile(
      title: Text(l10n.settingsShowRouteTrail),
      subtitle: Text(l10n.settingsShowRouteTrailSubtitle),
      value: values.showRouteTrail,
      onChanged: (value) => onChanged(MapDisplaySetting.routeTrail, value),
    ),
    SwitchListTile(
      title: Text(l10n.settingsCommunityCoverage),
      subtitle: Text(
        values.communityCoverageAvailable
            ? l10n.settingsCommunityCoverageDownloaded
            : l10n.settingsCommunityCoverageNeedDownload,
      ),
      value: values.showCommunityCoverage,
      onChanged: values.communityCoverageAvailable
          ? (value) => onChanged(MapDisplaySetting.communityCoverage, value)
          : null,
      secondary: values.communityCoverageAvailable
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: l10n.settingsClearDownloadedCoverageTooltip,
              onPressed: onClearCommunityCoverage,
            )
          : null,
    ),
    SwitchListTile(
      title: Text(l10n.settingsShowHeatmap),
      subtitle: Text(l10n.settingsShowHeatmapSubtitle),
      value: values.showHeatmap,
      onChanged: (value) => onChanged(MapDisplaySetting.heatmap, value),
    ),
    SwitchListTile(
      title: Text(l10n.settingsShowPredictionRings),
      subtitle: Text(l10n.settingsShowPredictionRingsSubtitle),
      value: values.showPredictionRings,
      onChanged: (value) => onChanged(MapDisplaySetting.predictionRings, value),
    ),
  ];
}
