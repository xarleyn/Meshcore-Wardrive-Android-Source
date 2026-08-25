import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/models.dart';
import '../../../services/map_lod_service.dart';
import '../../../utils/community_coverage.dart';
import 'sample_details_sheet.dart';

enum RepeaterInfoAction { filter, showOnMap }

enum RepeaterListAction { details, showOnMap }

class RepeaterListResult {
  const RepeaterListResult({required this.repeater, required this.action});

  final Repeater repeater;
  final RepeaterListAction action;
}

class SampleInfoDialog extends StatelessWidget {
  const SampleInfoDialog({
    required this.sample,
    required this.repeaterDisplay,
    required this.responses,
    this.ductingLabel,
    this.ductingColor,
    this.resolveRepeaterName,
    super.key,
  });

  final Sample sample;
  final String repeaterDisplay;

  /// Successful responses from the same ping burst, strongest first.
  final List<Sample> responses;

  final String? ductingLabel;
  final Color? ductingColor;

  /// Resolves a repeater node id to its known display name, if any.
  final String? Function(String? nodeId)? resolveRepeaterName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timestamp = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_Hms().format(sample.timestamp);
    final pingStatus = sample.pingSuccess == true
        ? l10n.mapStatusSuccess
        : sample.pingSuccess == false
        ? l10n.mapStatusFailed
        : l10n.mapStatusGpsOnly;
    final hasSignalData = sample.rssi != null || sample.snr != null;

    return AlertDialog(
      title: Text(l10n.mapSampleInfo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelValue(label: l10n.mapStatusLabel, value: pingStatus),
          const SizedBox(height: 8),
          Text(l10n.mapTimeLabel(timestamp), style: _secondaryStyle),
          const SizedBox(height: 8),
          Text(l10n.mapLat(sample.position.latitude.toStringAsFixed(6))),
          Text(l10n.mapLon(sample.position.longitude.toStringAsFixed(6))),
          if (sample.path != null) ...[
            const Divider(height: 16),
            const SizedBox(height: 8),
            _LabelValue(
              label: l10n.mapRepeaterLabel,
              value: repeaterDisplay,
              valueStyle: const TextStyle(fontFamily: 'monospace'),
              expandValue: true,
            ),
          ],
          if (hasSignalData) const Divider(height: 16),
          if (hasSignalData) const SizedBox(height: 8),
          if (sample.rssi != null)
            _LabelValue(label: l10n.mapRssiLabel, value: '${sample.rssi} dBm'),
          if (sample.snr != null)
            _LabelValue(label: l10n.mapSnrLabel, value: '${sample.snr} dB'),
          if (sample.responseTimeMs != null) ...[
            const SizedBox(height: 4),
            _LabelValue(
              label: l10n.mapResponseLabel,
              value: '${sample.responseTimeMs} ms',
            ),
          ],
          if (ductingLabel != null && ductingColor != null) ...[
            const Divider(height: 16),
            Row(
              children: [
                Text(
                  l10n.mapDuctingLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ductingColor!.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ductingLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ductingColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          _MoreDetailsLink(
            onTap: () => showSampleDetailsSheet(
              context,
              sample: sample,
              responses: responses,
              repeaterDisplay: repeaterDisplay,
              ductingLabel: ductingLabel,
              ductingColor: ductingColor,
              resolveRepeaterName: resolveRepeaterName,
            ),
          ),
        ],
      ),
      actions: [_CloseButton(label: l10n.mapClose)],
    );
  }
}

/// Compact hyperlink-style action opening a detailed bottom sheet while
/// keeping the hosting dialog small.
class _MoreDetailsLink extends StatelessWidget {
  const _MoreDetailsLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            AppLocalizations.of(context).mapMoreDetails,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class SampleClusterInfoDialog extends StatelessWidget {
  const SampleClusterInfoDialog({
    required this.cluster,
    this.resolveRepeaterName,
    super.key,
  });

  final SampleCluster cluster;

  /// Resolves a repeater node id to its known display name, if any.
  final String? Function(String? nodeId)? resolveRepeaterName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final newestTimestamp = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_Hms().format(cluster.newestSample.timestamp);
    return AlertDialog(
      title: Text(l10n.mapGroupedSamples(cluster.sampleCount)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mapSuccessfulCount(cluster.successfulCount)),
          Text(l10n.mapFailedCount(cluster.failedCount)),
          Text(l10n.mapGpsOnlyCount(cluster.gpsOnlyCount)),
          const SizedBox(height: 8),
          Text(l10n.mapNewest(newestTimestamp)),
          const SizedBox(height: 8),
          Text(l10n.mapZoomForBreakdown),
          const SizedBox(height: 4),
          _MoreDetailsLink(
            onTap: () => showMeasurementListSheet(
              context,
              title: l10n.mapMeasurementsTitle(cluster.samples.length),
              samples: cluster.samples,
              responderPool: cluster.samples,
              resolveRepeaterName: resolveRepeaterName,
            ),
          ),
        ],
      ),
      actions: [_CloseButton(label: l10n.mapClose)],
    );
  }
}

class RepeaterInfoDialog extends StatelessWidget {
  const RepeaterInfoDialog({required this.repeater, super.key});

  final Repeater repeater;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shortId =
        (repeater.id.length > 8 ? repeater.id.substring(0, 8) : repeater.id)
            .toUpperCase();
    return AlertDialog(
      title: Text(repeater.name ?? l10n.mapRepeaterFallback(shortId)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mapIdLabel(shortId),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          Text(l10n.mapLat(repeater.position.latitude.toStringAsFixed(6))),
          Text(l10n.mapLon(repeater.position.longitude.toStringAsFixed(6))),
          if (repeater.rssi != null) const SizedBox(height: 8),
          if (repeater.rssi != null)
            Text(l10n.mapRssiValue('${repeater.rssi}')),
          if (repeater.snr != null) Text(l10n.mapSnrValue('${repeater.snr}')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, RepeaterInfoAction.filter),
          child: Text(l10n.mapFilterByThis),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, RepeaterInfoAction.showOnMap),
          child: Text(l10n.mapShowOnMap),
        ),
        _CloseButton(label: l10n.mapClose),
      ],
    );
  }
}

class RepeaterListDialog extends StatelessWidget {
  const RepeaterListDialog({required this.repeaters, super.key});

  final List<Repeater> repeaters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapNearbyRepeaters(repeaters.length)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: repeaters.length,
          itemBuilder: (context, index) {
            final repeater = repeaters[index];
            return ListTile(
              leading: const Icon(Icons.cell_tower, color: Colors.purple),
              title: Text(
                repeater.name ?? l10n.mapRepeaterFallback(repeater.id),
              ),
              subtitle: Text(
                '${repeater.position.latitude.toStringAsFixed(4)}, '
                '${repeater.position.longitude.toStringAsFixed(4)}'
                '${repeater.snr != null ? ' • SNR: ${repeater.snr} dB' : ''}'
                '${repeater.rssi != null ? ' • RSSI: ${repeater.rssi} dBm' : ''}',
              ),
              onTap: () => Navigator.pop(
                context,
                RepeaterListResult(
                  repeater: repeater,
                  action: RepeaterListAction.details,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.location_searching),
                onPressed: () => Navigator.pop(
                  context,
                  RepeaterListResult(
                    repeater: repeater,
                    action: RepeaterListAction.showOnMap,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [_CloseButton(label: l10n.mapClose)],
    );
  }
}

class CoverageInfoDialog extends StatelessWidget {
  const CoverageInfoDialog({
    required this.coverage,
    this.cellSamples = const [],
    this.resolveRepeaterName,
    super.key,
  });

  final Coverage coverage;

  /// Ping measurements recorded inside this cell, newest first.
  final List<Sample> cellSamples;

  /// Resolves a repeater node id to its known display name, if any.
  final String? Function(String? nodeId)? resolveRepeaterName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = coverage.received + coverage.lost;
    final reliability = total > 0
        ? '${((coverage.received / total) * 100).toStringAsFixed(0)}%'
        : l10n.mapNoPingData;
    final prefixes =
        coverage.repeaters
            .map((id) => id.substring(0, id.length >= 4 ? 4 : id.length))
            .toSet()
            .toList()
          ..sort();

    return AlertDialog(
      title: Text(l10n.mapCoverageSquareInfo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelValue(
            label: l10n.mapSamplesLabel,
            value: total.toStringAsFixed(1),
          ),
          const SizedBox(height: 8),
          _LabelValue(label: l10n.mapSuccessRateLabel, value: reliability),
          const SizedBox(height: 8),
          _LabelValue(
            label: l10n.mapReceivedLabel,
            value: coverage.received.toStringAsFixed(1),
            labelStyle: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
            expandValue: true,
          ),
          const SizedBox(height: 4),
          _LabelValue(
            label: l10n.mapLostLabel,
            value: coverage.lost.toStringAsFixed(1),
            labelStyle: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            expandValue: true,
          ),
          if (coverage.received > 0) ...[
            const SizedBox(height: 8),
            _LabelValue(
              label: l10n.mapRepeatersHeard,
              value: '${prefixes.length}',
            ),
            const SizedBox(height: 4),
            _LabelValue(
              label: l10n.mapRepeaterIds,
              value: prefixes.isEmpty ? l10n.settingsNone : prefixes.join(', '),
              valueStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
              expandValue: true,
            ),
          ],
          const SizedBox(height: 4),
          _MoreDetailsLink(
            onTap: () => showMeasurementListSheet(
              context,
              title: l10n.mapMeasurementsTitle(cellSamples.length),
              samples: cellSamples,
              responderPool: cellSamples,
              resolveRepeaterName: resolveRepeaterName,
            ),
          ),
        ],
      ),
      actions: [_CloseButton(label: l10n.mapClose)],
    );
  }
}

class CommunityCellInfoDialog extends StatelessWidget {
  const CommunityCellInfoDialog({required this.cell, super.key});

  final CommunityCoverageCell cell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = cell.received + cell.lost;
    final successRate = total > 0
        ? ((cell.received / total) * 100).toStringAsFixed(1)
        : '0';
    final lastUpdate = cell.lastUpdate.isEmpty
        ? l10n.settingsUnknown
        : cell.lastUpdate;
    final parsedLastUpdate = DateTime.tryParse(lastUpdate);
    final lastUpdateDisplay = parsedLastUpdate == null
        ? lastUpdate
        : DateFormat.yMMMd(Localizations.localeOf(context).toString())
              .add_Hm()
              .format(parsedLastUpdate.toLocal());
    final repeatersText = cell.repeaters.isEmpty
        ? l10n.settingsNone
        : cell.repeaters.entries
              .map((entry) {
                final repeater = entry.value as Map<String, dynamic>;
                final name = repeater['name'] ?? entry.key;
                final rssi = repeater['rssi'];
                final snr = repeater['snr'];
                return '$name${rssi != null ? ' (RSSI: $rssi' : ''}'
                    '${snr != null
                        ? ', SNR: $snr)'
                        : rssi != null
                        ? ')'
                        : ''}';
              })
              .join('\n');

    return AlertDialog(
      title: Text(l10n.settingsCommunityCoverage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mapCommunitySuccessRate(successRate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('${l10n.mapReceivedLabel}${cell.received.toStringAsFixed(1)}'),
          Text('${l10n.mapLostLabel}${cell.lost.toStringAsFixed(1)}'),
          Text(l10n.mapSamplesCount('${cell.samples}')),
          const SizedBox(height: 8),
          Text(
            l10n.mapRepeatersHeader,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(repeatersText, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Text(l10n.mapLastUpdate(lastUpdateDisplay), style: _secondaryStyle),
          Text(
            l10n.mapAppVersionLabel(
              cell.appVersion.isEmpty ? l10n.settingsUnknown : cell.appVersion,
            ),
            style: _secondaryStyle,
          ),
        ],
      ),
      actions: [_CloseButton(label: l10n.mapClose)],
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({
    required this.label,
    required this.value,
    this.labelStyle = const TextStyle(fontWeight: FontWeight.bold),
    this.valueStyle,
    this.expandValue = false,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle? valueStyle;
  final bool expandValue;

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(value, style: valueStyle);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        if (expandValue) Expanded(child: valueWidget) else valueWidget,
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(label),
    );
  }
}

const _secondaryStyle = TextStyle(fontSize: 12, color: Colors.grey);
