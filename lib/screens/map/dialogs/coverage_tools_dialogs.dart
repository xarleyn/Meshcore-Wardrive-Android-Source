import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/models.dart';

enum RepeaterFilterAction { select, clear }

class RepeaterFilterResult {
  const RepeaterFilterResult.select(this.repeaterId)
    : action = RepeaterFilterAction.select;

  const RepeaterFilterResult.clear()
    : action = RepeaterFilterAction.clear,
      repeaterId = null;

  final RepeaterFilterAction action;
  final String? repeaterId;
}

List<Coverage> coverageGaps(Iterable<Coverage> coverages) {
  final gaps = coverages.where((coverage) {
    final total = coverage.received + coverage.lost;
    return total > 0 && coverage.received / total < 0.3;
  }).toList();

  gaps.sort((a, b) {
    final aRate = a.received / (a.received + a.lost);
    final bRate = b.received / (b.received + b.lost);
    return aRate.compareTo(bRate);
  });
  return gaps;
}

class RepeaterFilterDialog extends StatelessWidget {
  const RepeaterFilterDialog({
    required this.repeaterIds,
    required this.repeaters,
    required this.selectedId,
    super.key,
  });

  final List<String> repeaterIds;
  final List<Repeater> repeaters;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapFilterByRepeater),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: repeaterIds.length,
          itemBuilder: (context, index) {
            final id = repeaterIds[index];
            final displayId = _displayId(id);
            final repeater = repeaters.cast<Repeater?>().firstWhere(
              (candidate) => candidate!.id == id,
              orElse: () => null,
            );
            final isSelected = selectedId == id;

            return ListTile(
              leading: Icon(
                Icons.cell_tower,
                color: isSelected ? Colors.blue : Colors.purple,
              ),
              title: Text(
                repeater?.name ?? l10n.mapRepeaterFallback(displayId),
              ),
              subtitle: Text(
                displayId,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.blue)
                  : null,
              onTap: () =>
                  Navigator.pop(context, RepeaterFilterResult.select(id)),
            );
          },
        ),
      ),
      actions: [
        if (selectedId != null && selectedId!.isNotEmpty)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const RepeaterFilterResult.clear()),
            child: Text(
              l10n.mapClearFilter,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.settingsCancel),
        ),
      ],
    );
  }
}

class CoverageGapsDialog extends StatelessWidget {
  const CoverageGapsDialog({required this.gaps, super.key});

  final List<Coverage> gaps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapCoverageGaps(gaps.length)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: gaps.length,
          itemBuilder: (context, index) {
            final gap = gaps[index];
            final total = gap.received + gap.lost;
            final rate = total > 0
                ? ((gap.received / total) * 100).toStringAsFixed(0)
                : '0';
            return ListTile(
              leading: Icon(
                Icons.warning,
                color: double.parse(rate) == 0 ? Colors.red : Colors.orange,
              ),
              title: Text(l10n.mapGapSuccessRate(rate)),
              subtitle: Text(
                l10n.mapGapSubtitle(
                  '${gap.position.latitude.toStringAsFixed(4)}, '
                  '${gap.position.longitude.toStringAsFixed(4)}',
                  gap.received.toStringAsFixed(1),
                  gap.lost.toStringAsFixed(1),
                ),
              ),
              onTap: () => Navigator.pop(context, gap),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.mapClose),
        ),
      ],
    );
  }
}

String _displayId(String id) =>
    (id.length > 8 ? id.substring(0, 8) : id).toUpperCase();
