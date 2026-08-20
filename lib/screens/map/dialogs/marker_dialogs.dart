import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/models.dart';

enum PlannedMarkerAction { delete }

class PrivacyZoneDraft {
  const PrivacyZoneDraft({required this.radiusMeters, this.label});

  final double radiusMeters;
  final String? label;
}

class AddPlannedMarkerDialog extends StatefulWidget {
  const AddPlannedMarkerDialog({required this.position, super.key});

  final LatLng position;

  @override
  State<AddPlannedMarkerDialog> createState() => _AddPlannedMarkerDialogState();
}

class _AddPlannedMarkerDialogState extends State<AddPlannedMarkerDialog> {
  final _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.mapAddPlannedRepeater),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.position.latitude.toStringAsFixed(5)}, '
            '${widget.position.longitude.toStringAsFixed(5)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: l10n.settingsLabelOptional,
              hintText: l10n.mapPlannedRepeaterHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.settingsCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _labelController.text),
          child: Text(l10n.mapAddMarker),
        ),
      ],
    );
  }
}

class PlannedMarkerInfoDialog extends StatelessWidget {
  const PlannedMarkerInfoDialog({
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.label,
    super.key,
  });

  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formattedDate = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(createdAt);

    return AlertDialog(
      title: Text(label ?? l10n.mapPlannedRepeater),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mapLat(latitude.toStringAsFixed(6))),
          Text(l10n.mapLon(longitude.toStringAsFixed(6))),
          Text(
            l10n.mapAddedOn(formattedDate),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, PlannedMarkerAction.delete),
          child: Text(
            l10n.mapDelete,
            style: const TextStyle(color: Colors.red),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.mapClose),
        ),
      ],
    );
  }
}

class AddPrivacyZoneDialog extends StatefulWidget {
  const AddPrivacyZoneDialog({required this.center, super.key});

  final LatLng center;

  @override
  State<AddPrivacyZoneDialog> createState() => _AddPrivacyZoneDialogState();
}

class _AddPrivacyZoneDialogState extends State<AddPrivacyZoneDialog> {
  final _labelController = TextEditingController();
  double _selectedRadius = 1000;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radiusOptions = [
      (label: l10n.settingsRadius500m, meters: 500.0),
      (label: l10n.settingsRadius1km, meters: 1000.0),
      (label: l10n.settingsRadius2km, meters: 2000.0),
      (label: l10n.settingsRadius5km, meters: 5000.0),
    ];

    return AlertDialog(
      title: Text(l10n.mapAddPrivacyZone),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsAddImpossibleZoneCenter(
              widget.center.latitude.toStringAsFixed(5),
              widget.center.longitude.toStringAsFixed(5),
            ),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(l10n.mapPrivacyZoneBlurb, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: l10n.settingsLabelOptional,
              hintText: l10n.mapPrivacyZoneHint,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.settingsRadius,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          RadioGroup<double>(
            groupValue: _selectedRadius,
            onChanged: (value) {
              if (value != null) setState(() => _selectedRadius = value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in radiusOptions)
                  RadioListTile<double>(
                    title: Text(option.label),
                    value: option.meters,
                    dense: true,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.settingsCancel),
        ),
        TextButton(
          onPressed: () {
            final label = _labelController.text;
            Navigator.pop(
              context,
              PrivacyZoneDraft(
                radiusMeters: _selectedRadius,
                label: label.isEmpty ? null : label,
              ),
            );
          },
          child: Text(l10n.settingsAddZone),
        ),
      ],
    );
  }
}

class DeleteSampleConfirmationDialog extends StatelessWidget {
  const DeleteSampleConfirmationDialog({required this.sample, super.key});

  final Sample sample;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = sample.pingSuccess == true
        ? 'success'
        : sample.pingSuccess == false
        ? 'fail'
        : 'gps';
    final timestamp = DateFormat.MMMd(
      Localizations.localeOf(context).toString(),
    ).add_Hm().format(sample.timestamp);

    return AlertDialog(
      title: Text(l10n.mapDeleteSample),
      content: Text(l10n.mapDeleteSampleConfirm(status, timestamp)),
      actions: _deleteActions(context),
    );
  }
}

class DeleteCoverageConfirmationDialog extends StatelessWidget {
  const DeleteCoverageConfirmationDialog({required this.coverage, super.key});

  final Coverage coverage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = (coverage.received + coverage.lost).round();

    return AlertDialog(
      title: Text(l10n.mapDeleteCoverageCell),
      content: Text(l10n.mapDeleteCoverageCellBody(total, coverage.id)),
      actions: _deleteActions(context, deleteAll: true),
    );
  }
}

List<Widget> _deleteActions(BuildContext context, {bool deleteAll = false}) {
  final l10n = AppLocalizations.of(context);
  return [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: Text(l10n.settingsCancel),
    ),
    TextButton(
      onPressed: () => Navigator.pop(context, true),
      child: Text(
        deleteAll ? l10n.mapDeleteAll : l10n.mapDelete,
        style: const TextStyle(color: Colors.red),
      ),
    ),
  ];
}
