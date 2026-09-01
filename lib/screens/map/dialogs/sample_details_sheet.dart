import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/models.dart';
import '../../../utils/ping_burst.dart';

/// Opens the detailed measurement sheet describing one ping sample.
///
/// The sheet repeats the essentials shown in [SampleInfoDialog] and adds
/// everything recorded for the measurement plus the full list of repeaters
/// that answered the same ping burst, strongest signal first.
Future<void> showSampleDetailsSheet(
  BuildContext context, {
  required Sample sample,
  required List<Sample> responses,
  String? repeaterDisplay,
  String? ductingLabel,
  Color? ductingColor,
  String? Function(String? nodeId)? resolveRepeaterName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SampleDetailsSheet(
          sample: sample,
          responses: responses,
          repeaterDisplay: repeaterDisplay,
          ductingLabel: ductingLabel,
          ductingColor: ductingColor,
          resolveRepeaterName: resolveRepeaterName,
        ),
      ),
    ),
  );
}

class SampleDetailsSheet extends StatelessWidget {
  const SampleDetailsSheet({
    required this.sample,
    required this.responses,
    this.repeaterDisplay,
    this.ductingLabel,
    this.ductingColor,
    this.resolveRepeaterName,
    super.key,
  });

  final Sample sample;

  /// Successful responses from the same ping burst, strongest first.
  final List<Sample> responses;

  final String? repeaterDisplay;
  final String? ductingLabel;
  final Color? ductingColor;
  final String? Function(String? nodeId)? resolveRepeaterName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timestamp = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_Hms().format(sample.timestamp);
    final isPing = sample.pingSuccess != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mapSampleDetailsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _MeasurementDetails(
            sample: sample,
            timestamp: timestamp,
            repeaterDisplay: repeaterDisplay,
            ductingLabel: ductingLabel,
            ductingColor: ductingColor,
          ),
          if (isPing) ...[
            const SizedBox(height: 16),
            _ResponderSection(
              sample: sample,
              responses: responses,
              resolveRepeaterName: resolveRepeaterName,
            ),
          ],
        ],
      ),
    );
  }
}

class _MeasurementDetails extends StatelessWidget {
  const _MeasurementDetails({
    required this.sample,
    required this.timestamp,
    this.repeaterDisplay,
    this.ductingLabel,
    this.ductingColor,
  });

  final Sample sample;
  final String timestamp;
  final String? repeaterDisplay;
  final String? ductingLabel;
  final Color? ductingColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pingStatus = sample.pingSuccess == true
        ? l10n.mapStatusSuccess
        : sample.pingSuccess == false
        ? l10n.mapStatusFailed
        : l10n.mapStatusGpsOnly;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(label: l10n.mapStatusLabel, value: pingStatus),
        _DetailRow(label: l10n.mapTimeLabel(timestamp), value: null),
        _DetailRow(
          label: l10n.mapLat(sample.position.latitude.toStringAsFixed(6)),
          value: null,
        ),
        _DetailRow(
          label: l10n.mapLon(sample.position.longitude.toStringAsFixed(6)),
          value: null,
        ),
        _DetailRow(
          label: l10n.mapGeohashLabel,
          value: sample.geohash,
          valueStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        if (sample.path != null) ...[
          _DetailRow(
            label: l10n.mapRepeaterLabel,
            value: repeaterDisplay ?? sample.path!,
          ),
          _DetailRow(
            label: l10n.mapIdLabel(sample.path!),
            value: null,
            valueStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
        if (sample.rssi != null)
          _DetailRow(label: l10n.mapRssiLabel, value: '${sample.rssi} dBm'),
        if (sample.snr != null)
          _DetailRow(label: l10n.mapSnrLabel, value: '${sample.snr} dB'),
        if (sample.responseTimeMs != null)
          _DetailRow(
            label: l10n.mapResponseLabel,
            value: '${sample.responseTimeMs} ms',
          ),
        if (ductingLabel != null && ductingColor != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(l10n.mapDuctingLabel),
                const SizedBox(width: 4),
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
          ),
        if (sample.deviceId != null)
          _DetailRow(
            label: l10n.mapDeviceLabel,
            value: sample.deviceId!,
            valueStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        if (sample.source != null)
          _DetailRow(label: l10n.mapSourceLabel, value: sample.source!),
      ],
    );
  }
}

class _ResponderSection extends StatelessWidget {
  const _ResponderSection({
    required this.sample,
    required this.responses,
    this.resolveRepeaterName,
  });

  final Sample sample;
  final List<Sample> responses;
  final String? Function(String? nodeId)? resolveRepeaterName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (responses.isEmpty) {
      // GPS-only samples never carry responders, so only failed pings get an
      // explicit explanation.
      if (sample.pingSuccess == false) {
        return Text(l10n.mapNoResponders, style: _secondaryStyle);
      }
      return const SizedBox.shrink();
    }

    final bestRssi = PingBurst.bestRssi(responses);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.mapRespondersTitle(responses.length),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (bestRssi != null) ...[
          const SizedBox(height: 2),
          Text(l10n.mapBestSignal('$bestRssi dBm'), style: _secondaryStyle),
        ],
        const SizedBox(height: 4),
        ...[
          for (final response in responses)
            _ResponderTile(
              response: response,
              isCurrent: response.id == sample.id,
              repeaterName: resolveRepeaterName?.call(response.path),
            ),
        ],
      ],
    );
  }
}

/// Opens a scrollable list of measurements with their signal levels.
///
/// Used by the grouped-samples and coverage-cell dialogs: every row opens the
/// full [SampleDetailsSheet] for that measurement on top of the list.
Future<void> showMeasurementListSheet(
  BuildContext context, {
  required String title,
  required List<Sample> samples,
  List<Sample> responderPool = const [],
  String? Function(String? nodeId)? resolveRepeaterName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: MeasurementListSheet(
          title: title,
          samples: samples,
          responderPool: responderPool,
          resolveRepeaterName: resolveRepeaterName,
        ),
      ),
    ),
  );
}

class MeasurementListSheet extends StatelessWidget {
  const MeasurementListSheet({
    required this.title,
    required this.samples,
    this.responderPool = const [],
    this.resolveRepeaterName,
    super.key,
  });

  final String title;

  /// Measurements rendered newest first.
  final List<Sample> samples;

  /// Candidate samples used to reconstruct responder bursts when a row is
  /// opened; defaults to nothing beyond each measurement itself.
  final List<Sample> responderPool;

  final String? Function(String? nodeId)? resolveRepeaterName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = [...samples]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(l10n.mapNoPingData, style: _secondaryStyle),
              ),
            )
          else
            for (final sample in sorted)
              _MeasurementTile(
                sample: sample,
                responderPool: responderPool,
                resolveRepeaterName: resolveRepeaterName,
              ),
        ],
      ),
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({
    required this.sample,
    required this.responderPool,
    this.resolveRepeaterName,
  });

  final Sample sample;
  final List<Sample> responderPool;
  final String? Function(String? nodeId)? resolveRepeaterName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timestamp = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_Hms().format(sample.timestamp);
    final nodeId = sample.path;
    final shortId = nodeId == null || nodeId.isEmpty
        ? ''
        : (nodeId.length > 8 ? nodeId.substring(0, 8) : nodeId).toUpperCase();
    final metrics = [
      if (sample.rssi != null) '${l10n.mapRssiLabel}${sample.rssi} dBm',
      if (sample.snr != null) '${l10n.mapSnrLabel}${sample.snr} dB',
      if (sample.responseTimeMs != null)
        '${l10n.mapResponseLabel}${sample.responseTimeMs} ms',
    ].join(' • ');
    final titleText = nodeId != null && nodeId.isNotEmpty
        ? resolveRepeaterName?.call(nodeId) ?? l10n.mapRepeaterFallback(shortId)
        : sample.pingSuccess == false
        ? l10n.mapStatusFailed
        : l10n.mapStatusGpsOnly;

    return InkWell(
      onTap: () => showSampleDetailsSheet(
        context,
        sample: sample,
        responses: PingBurst.responsesFor(sample, responderPool),
        resolveRepeaterName: resolveRepeaterName,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                _statusIcon(sample),
                size: 20,
                color: _statusIconColor(sample),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titleText),
                  Text(timestamp, style: _secondaryStyle),
                  if (metrics.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(metrics, style: _secondaryStyle),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _statusIcon(Sample sample) {
    if (sample.pingSuccess == true) return rssiIcon(sample.rssi);
    if (sample.pingSuccess == false) {
      return Icons.signal_cellular_connected_no_internet_0_bar;
    }
    return Icons.location_on_outlined;
  }

  static Color _statusIconColor(Sample sample) {
    if (sample.pingSuccess == true) return rssiColor(sample.rssi);
    if (sample.pingSuccess == false) return Colors.red;
    return Colors.blueGrey;
  }
}

class _ResponderTile extends StatelessWidget {
  const _ResponderTile({
    required this.response,
    required this.isCurrent,
    this.repeaterName,
  });

  final Sample response;
  final bool isCurrent;
  final String? repeaterName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nodeId = response.path ?? '';
    final shortId = (nodeId.length > 8 ? nodeId.substring(0, 8) : nodeId)
        .toUpperCase();
    final metrics = [
      '${l10n.mapRssiLabel}'
          '${response.rssi?.toString() ?? l10n.mapNotAvailable} dBm',
      '${l10n.mapSnrLabel}'
          '${response.snr?.toString() ?? l10n.mapNotAvailable} dB',
      '${l10n.mapResponseLabel}'
          '${response.responseTimeMs?.toString() ?? l10n.mapNotAvailable} ms',
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              rssiIcon(response.rssi),
              size: 20,
              color: rssiColor(response.rssi),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(repeaterName ?? l10n.mapRepeaterFallback(shortId)),
                Text(nodeId, style: _monoStyle),
                const SizedBox(height: 2),
                Text(metrics, style: _secondaryStyle),
              ],
            ),
          ),
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Tooltip(
                message: l10n.mapThisMeasurement,
                child: const Icon(Icons.my_location, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}

/// Icon reflecting the reported RSSI strength.
IconData rssiIcon(int? rssi) {
  if (rssi == null) return Icons.signal_cellular_connected_no_internet_0_bar;
  if (rssi >= -85) return Icons.signal_cellular_alt;
  if (rssi >= -100) return Icons.signal_cellular_alt_2_bar;
  return Icons.signal_cellular_alt_1_bar;
}

/// Color reflecting the reported RSSI strength.
Color rssiColor(int? rssi) {
  if (rssi == null) return Colors.grey;
  if (rssi >= -85) return Colors.green;
  if (rssi >= -100) return Colors.orange;
  return Colors.red;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueStyle});

  /// Full text rendered after [label]; `null` renders only the label, which
  /// then carries its own embedded value.
  final String? value;
  final String label;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final valueText = value;
    final labelText = Text(label, style: valueStyle);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rows without a separate value embed it in the label and may be
          // long (timestamps, coordinates), so only those get to wrap.
          if (valueText == null) Flexible(child: labelText) else labelText,
          if (valueText != null)
            Expanded(child: Text(valueText, style: valueStyle)),
        ],
      ),
    );
  }
}

const _secondaryStyle = TextStyle(fontSize: 12, color: Colors.grey);
const _monoStyle = TextStyle(fontFamily: 'monospace', fontSize: 12);
