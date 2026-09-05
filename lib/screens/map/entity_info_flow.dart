import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../../services/aggregation_service.dart';
import '../../services/lora_companion_service.dart';
import '../../services/map_lod_service.dart';
import '../../utils/community_coverage.dart';
import 'ducting_presentation.dart';
import '../../utils/geohash_utils.dart';
import '../../utils/ping_burst.dart';
import 'dialogs/coverage_tools_dialogs.dart';
import 'dialogs/map_entity_dialogs.dart';

/// Shortens a node or repeater id to its 8-character display prefix.
String shortNodeId(String nodeId) =>
    (nodeId.length > 8 ? nodeId.substring(0, 8) : nodeId).toUpperCase();

/// Entity info dialogs for the map screen.
///
/// Covers sample, sample-cluster, coverage-cell, repeater, repeater-list,
/// repeater-filter, coverage-gap, and community-cell interactions. The flow
/// owns no state: repeater display names resolve through the injected
/// companion service and screen data, and persistent mutations (the
/// include-only repeater filter) delegate to [onFilterRepeater].
class EntityInfoFlow {
  /// Camera zoom used when flying to a repeater or coverage gap.
  static const double _focusZoom = 15.0;

  const EntityInfoFlow({
    required this.context,
    required this.onShowSnackBar,
    required this.loraCompanion,
    required this.repeaters,
    required this.samples,
    required this.aggregationResult,
    required this.communityCoverage,
    required this.showCommunityCoverage,
    required this.includeOnlyRepeaters,
    required this.coverageLodPrecision,
    required this.onFilterRepeater,
    required this.moveMapTo,
  });

  /// Screen context used for mounted checks, localization, and dialogs.
  final BuildContext context;

  /// Shows a transient message; the owner guards this callback with its own
  /// mounted check.
  final void Function(String message) onShowSnackBar;

  final LoRaCompanionService loraCompanion;

  /// Read-through getters: the map screen state changes while this flow is
  /// alive, so every access resolves the current value.
  final List<Repeater> Function() repeaters;
  final List<Sample> Function() samples;
  final AggregationResult? Function() aggregationResult;

  /// Downloaded community coverage and its display toggle.
  final Map<String, dynamic>? Function() communityCoverage;
  final bool Function() showCommunityCoverage;

  /// Current include-only repeater filter, shown by the filter picker.
  final String? Function() includeOnlyRepeaters;

  /// Current coverage LOD precision for community-coverage hit testing.
  final int Function() coverageLodPrecision;

  /// Persists the include-only repeater filter and reloads map data.
  final Future<void> Function(String? repeaterId) onFilterRepeater;

  /// Moves the map camera to [position] at [zoom].
  final void Function(LatLng position, double zoom) moveMapTo;

  /// Resolves a repeater display name by id or two-character prefix.
  String? getRepeaterName(String? repeaterId) {
    if (repeaterId == null) return null;

    // If it's a 2-char prefix, try to expand it first
    String? fullId = repeaterId;
    if (repeaterId.length == 2) {
      fullId = loraCompanion.matchRepeaterPrefix(repeaterId);
      if (fullId == null) {
        // No match found, return the 2-char prefix as-is
        return repeaterId;
      }
    }

    // First check discovered repeaters list
    final repeater = repeaters().firstWhere(
      (candidate) => candidate.id == fullId,
      orElse: () => Repeater(
        id: fullId!,
        position: const LatLng(0, 0),
        timestamp: DateTime.now(),
      ),
    );
    if (repeater.name != null) return repeater.name;

    // Fall back to checking the companion's contact cache
    final loraRepeater = loraCompanion.getRepeaterLocation(fullId);
    return loraRepeater?.name;
  }

  /// Details of a tapped sample, with its ping-burst responses.
  void showSampleInfo(Sample sample) {
    final l10n = AppLocalizations.of(context);
    final repeaterName = sample.path != null
        ? getRepeaterName(sample.path)
        : null;
    final idOrName = repeaterName ?? sample.path ?? l10n.settingsUnknown;
    final repeaterDisplay =
        repeaterName ??
        (idOrName.length > 8
            ? idOrName.substring(0, 8).toUpperCase()
            : idOrName.toUpperCase());
    final ductingRisk = sample.ductingRisk;

    showDialog(
      context: context,
      builder: (dialogContext) => SampleInfoDialog(
        sample: sample,
        responses: PingBurst.responsesFor(sample, samples()),
        repeaterDisplay: repeaterDisplay,
        resolveRepeaterName: getRepeaterName,
        ductingLabel: ductingRisk == null
            ? null
            : localizedDuctingRisk(l10n, ductingRisk),
        ductingColor: ductingRisk == null
            ? null
            : ductingRiskColor(ductingRisk),
      ),
    );
  }

  /// Details of a tapped multi-sample cluster.
  void showSampleClusterInfo(SampleCluster cluster) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => SampleClusterInfoDialog(
        cluster: cluster,
        resolveRepeaterName: getRepeaterName,
      ),
    );
  }

  /// Details of a tapped repeater, with show-on-map and filter actions.
  Future<void> showRepeaterInfo(Repeater repeater) async {
    final action = await showDialog<RepeaterInfoAction>(
      context: context,
      builder: (dialogContext) => RepeaterInfoDialog(repeater: repeater),
    );
    if (!context.mounted) return;

    if (action == RepeaterInfoAction.showOnMap) {
      moveMapTo(repeater.position, _focusZoom);
      return;
    }
    if (action != RepeaterInfoAction.filter || !context.mounted) return;

    final message = AppLocalizations.of(context)
        .mapFilteringBy(shortNodeId(repeater.id));
    await onFilterRepeater(repeater.id);
    onShowSnackBar(message);
  }

  /// Details of a tapped coverage cell, listing the samples inside it.
  void showCoverageInfo(Coverage coverage) {
    showDialog(
      context: context,
      builder: (dialogContext) => CoverageInfoDialog(
        coverage: coverage,
        cellSamples: coverageCellSamples(coverage.id),
        resolveRepeaterName: getRepeaterName,
      ),
    );
  }

  /// Samples belonging to the coverage cell with [coverageId].
  ///
  /// Cell ids may be LOD-coarsened, so membership is decided by geohash
  /// prefix: a sample's full-precision key always starts with every coarser
  /// cell key that contains it.
  List<Sample> coverageCellSamples(String coverageId) {
    final precision = coverageId.length;
    final matches = samples().where((sample) {
      final hash = sample.geohash;
      if (hash.length >= precision) {
        return hash.substring(0, precision) == coverageId;
      }
      return GeohashUtils.coverageKey(
            sample.position.latitude,
            sample.position.longitude,
            precision: precision,
          ) ==
          coverageId;
    }).toList();
    matches.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return matches;
  }

  /// Repeater list dialog with show-on-map and detail actions.
  Future<void> showRepeatersDialog() async {
    final result = await showDialog<RepeaterListResult>(
      context: context,
      builder: (dialogContext) => RepeaterListDialog(repeaters: repeaters()),
    );
    if (result == null || !context.mounted) return;
    if (result.action == RepeaterListAction.showOnMap) {
      moveMapTo(result.repeater.position, _focusZoom);
    } else {
      await showRepeaterInfo(result.repeater);
    }
  }

  /// Picker that narrows the map to a single repeater's coverage.
  Future<void> showRepeaterFilterPicker() async {
    // Collect all known repeater IDs from coverage data and discovered repeaters
    final Set<String> knownIds = {};
    final aggregation = aggregationResult();
    if (aggregation != null) {
      for (final cov in aggregation.coverages) {
        knownIds.addAll(cov.repeaters);
      }
    }
    for (final repeater in repeaters()) {
      knownIds.add(repeater.id);
    }

    if (knownIds.isEmpty) {
      onShowSnackBar(AppLocalizations.of(context).mapNoRepeatersYet);
      return;
    }

    final sortedIds = knownIds.toList()..sort();

    final result = await showDialog<RepeaterFilterResult>(
      context: context,
      builder: (dialogContext) => RepeaterFilterDialog(
        repeaterIds: sortedIds,
        repeaters: repeaters(),
        selectedId: includeOnlyRepeaters(),
      ),
    );

    if (result == null || !context.mounted) return;
    final selectedId = result.action == RepeaterFilterAction.clear
        ? null
        : result.repeaterId;
    await onFilterRepeater(selectedId);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final message = selectedId == null
        ? l10n.mapRepeaterFilterCleared
        : l10n.mapShowingCoverageFrom(shortNodeId(selectedId));
    onShowSnackBar(message);
  }

  /// Lists coverage holes and flies to the one the user picks.
  Future<void> findCoverageGaps() async {
    final aggregation = aggregationResult();
    if (aggregation == null || aggregation.coverages.isEmpty) {
      onShowSnackBar(AppLocalizations.of(context).mapNoCoverageYet);
      return;
    }

    final gaps = coverageGaps(aggregation.coverages);

    if (gaps.isEmpty) {
      onShowSnackBar(AppLocalizations.of(context).mapNoCoverageGaps);
      return;
    }

    final selected = await showDialog<Coverage>(
      context: context,
      builder: (dialogContext) => CoverageGapsDialog(gaps: gaps),
    );
    if (selected != null) moveMapTo(selected.position, _focusZoom);
  }

  /// Community-coverage hit test behind the map's tap handler.
  void handleMapTap(LatLng point) {
    final coverage = communityCoverage();
    if (!showCommunityCoverage() || coverage == null) return;

    final cells = CommunityCoverage.aggregate(
      coverage,
      precision: coverageLodPrecision(),
    );
    final hit = CommunityCoverage.hitTest(cells, point);
    if (hit != null) {
      showCommunityCellInfo(hit);
    }
  }

  /// Details of a tapped community coverage cell.
  void showCommunityCellInfo(CommunityCoverageCell cell) {
    showDialog(
      context: context,
      builder: (dialogContext) => CommunityCellInfoDialog(cell: cell),
    );
  }
}
