import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/models.dart';

enum PlannedMarkerAction { delete }

enum MapLongPressAction { plannedRepeater, privacyZone, impossibleZone }

class PrivacyZoneDraft {
  const PrivacyZoneDraft({required this.radiusMeters, this.label});

  final double radiusMeters;
  final String? label;
}

class ImpossibleZoneDraft {
  const ImpossibleZoneDraft({
    required this.center,
    required this.radiusMeters,
    required this.label,
  });

  final LatLng center;
  final double radiusMeters;
  final String? label;
}

class MapLongPressActionSheet extends StatelessWidget {
  const MapLongPressActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Text(
                l10n.mapLongPressActionTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _MapLongPressActionTile(
              icon: Icons.cell_tower_outlined,
              title: l10n.mapAddPlannedRepeater,
              subtitle: l10n.mapLongPressPlannedRepeaterSubtitle,
              action: MapLongPressAction.plannedRepeater,
            ),
            _MapLongPressActionTile(
              icon: Icons.privacy_tip_outlined,
              title: l10n.mapAddPrivacyZone,
              subtitle: l10n.mapLongPressPrivacyZoneSubtitle,
              action: MapLongPressAction.privacyZone,
            ),
            _MapLongPressActionTile(
              icon: Icons.gps_off_outlined,
              title: l10n.settingsAddImpossibleZone,
              subtitle: l10n.mapLongPressImpossibleZoneSubtitle,
              action: MapLongPressAction.impossibleZone,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLongPressActionTile extends StatelessWidget {
  const _MapLongPressActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final MapLongPressAction action;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => Navigator.pop(context, action),
    );
  }
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

class AddPrivacyZoneDialog extends StatelessWidget {
  const AddPrivacyZoneDialog({required this.center, super.key});

  final LatLng center;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _AddCircularZoneDialog<PrivacyZoneDraft>(
      center: center,
      title: l10n.mapAddPrivacyZone,
      blurb: l10n.mapPrivacyZoneBlurb,
      labelHint: l10n.mapPrivacyZoneHint,
      createDraft: (radiusMeters, label) =>
          PrivacyZoneDraft(radiusMeters: radiusMeters, label: label),
    );
  }
}

class AddImpossibleZoneDialog extends StatelessWidget {
  const AddImpossibleZoneDialog({required this.center, super.key});

  final LatLng center;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _AddCircularZoneDialog<ImpossibleZoneDraft>(
      center: center,
      title: l10n.settingsAddImpossibleZone,
      blurb: l10n.settingsAddImpossibleZoneBlurb,
      labelHint: l10n.settingsLabelHintAirport,
      createDraft: (radiusMeters, label) => ImpossibleZoneDraft(
        center: center,
        radiusMeters: radiusMeters,
        label: label,
      ),
    );
  }
}

class _AddCircularZoneDialog<T> extends StatefulWidget {
  const _AddCircularZoneDialog({
    required this.center,
    required this.title,
    required this.blurb,
    required this.labelHint,
    required this.createDraft,
  });

  final LatLng center;
  final String title;
  final String blurb;
  final String labelHint;
  final T Function(double radiusMeters, String? label) createDraft;

  @override
  State<_AddCircularZoneDialog<T>> createState() =>
      _AddCircularZoneDialogState<T>();
}

class _AddCircularZoneDialogState<T> extends State<_AddCircularZoneDialog<T>> {
  static const double minRadiusMeters = 50;
  static const double maxRadiusMeters = 10000;
  static const double _radiusStepMeters = 50;

  final _labelController = TextEditingController();
  final _radiusController = TextEditingController(text: '1000');
  double _selectedRadius = 1000;

  @override
  void dispose() {
    _labelController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _onRadiusChanged(String value) {
    final meters = double.tryParse(value);
    if (meters == null) return;
    setState(() {
      _selectedRadius = meters.clamp(minRadiusMeters, maxRadiusMeters);
    });
  }

  void _onSliderChanged(double value) {
    setState(() {
      _selectedRadius = value;
      _radiusController.text = value.toStringAsFixed(0);
    });
  }

  void _normalizeRadiusText(String value) {
    final text = _selectedRadius.toStringAsFixed(0);
    if (_radiusController.text != text) {
      _radiusController.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
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
            Text(widget.blurb, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              key: const Key('zone_dialog_label'),
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l10n.settingsLabelOptional,
                hintText: widget.labelHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('zone_dialog_radius'),
              controller: _radiusController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.settingsRadiusMeters,
                suffixText: 'm',
              ),
              onChanged: _onRadiusChanged,
              onSubmitted: _normalizeRadiusText,
            ),
            Slider(
              value: _selectedRadius,
              min: minRadiusMeters,
              max: maxRadiusMeters,
              divisions:
                  ((maxRadiusMeters - minRadiusMeters) / _radiusStepMeters)
                      .round(),
              label: '${_selectedRadius.toStringAsFixed(0)} m',
              onChanged: _onSliderChanged,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.settingsCancel),
        ),
        TextButton(
          onPressed: () {
            _normalizeRadiusText(_radiusController.text);
            final label = _labelController.text.trim();
            Navigator.pop(
              context,
              widget.createDraft(_selectedRadius, label.isEmpty ? null : label),
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
