import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/models.dart';
import '../../../utils/repeater_contacts.dart';

enum RepeaterPickAction { select, manualEntry, clear }

class RepeaterPickResult {
  const RepeaterPickResult.select(this.repeaterId)
    : action = RepeaterPickAction.select;

  const RepeaterPickResult.manualEntry()
    : action = RepeaterPickAction.manualEntry,
      repeaterId = null;

  const RepeaterPickResult.clear()
    : action = RepeaterPickAction.clear,
      repeaterId = null;

  final RepeaterPickAction action;
  final String? repeaterId;
}

/// Searchable picker for previously found repeaters. Each row shows the
/// advertised name together with the repeater ID.
Future<RepeaterPickResult?> showRepeaterPickerDialog({
  required BuildContext context,
  required List<Repeater> repeaters,
  String? selectedId,
}) {
  return showDialog<RepeaterPickResult>(
    context: context,
    builder: (context) =>
        RepeaterPickerDialog(repeaters: repeaters, selectedId: selectedId),
  );
}

class RepeaterPickerDialog extends StatefulWidget {
  const RepeaterPickerDialog({
    required this.repeaters,
    required this.selectedId,
    super.key,
  });

  final List<Repeater> repeaters;
  final String? selectedId;

  @override
  State<RepeaterPickerDialog> createState() => _RepeaterPickerDialogState();
}

class _RepeaterPickerDialogState extends State<RepeaterPickerDialog> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Repeater> get _filteredRepeaters {
    final query = _query.trim().toUpperCase();
    return widget.repeaters.where((repeater) {
      if (query.isEmpty) return true;
      return repeater.id.toUpperCase().contains(query) ||
          (repeater.name?.toUpperCase().contains(query) ?? false);
    }).toList()..sort(compareRepeaterContacts);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repeaters = _filteredRepeaters;
    return AlertDialog(
      title: Text(l10n.settingsTargetRepeater),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.settingsTargetRepeaterSearchHint,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: repeaters.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text(l10n.mapNoRepeatersFound)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: repeaters.length,
                        itemBuilder: (context, index) {
                          return _buildTile(context, repeaters[index]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const RepeaterPickResult.manualEntry()),
          child: Text(l10n.settingsEnterRepeaterManually),
        ),
        if (widget.selectedId case final selectedId? when selectedId.isNotEmpty)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const RepeaterPickResult.clear()),
            child: Text(
              l10n.settingsClear,
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

  Widget _buildTile(BuildContext context, Repeater repeater) {
    final displayId = displayRepeaterId(repeater.id);
    final isSelected =
        widget.selectedId?.toUpperCase() == repeater.id.toUpperCase();
    return ListTile(
      leading: Icon(Icons.cell_tower, color: isSelected ? Colors.blue : null),
      title: Text(repeater.name ?? displayId),
      subtitle: Text(
        displayId,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
      onTap: () => Navigator.pop(
        context,
        RepeaterPickResult.select(repeater.id.toUpperCase()),
      ),
    );
  }
}

/// Short uppercase form of a repeater ID used for display.
String displayRepeaterId(String id) =>
    (id.length > 8 ? id.substring(0, 8) : id).toUpperCase();
