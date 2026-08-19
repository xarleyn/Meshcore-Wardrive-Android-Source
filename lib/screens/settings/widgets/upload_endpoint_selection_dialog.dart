import 'package:flutter/material.dart';

import '../../../services/upload_service.dart';

class UploadEndpointSelectionDialog extends StatefulWidget {
  const UploadEndpointSelectionDialog({
    required this.endpoints,
    required this.initiallySelectedNames,
    super.key,
  });

  final List<UploadEndpoint> endpoints;
  final Iterable<String> initiallySelectedNames;

  @override
  State<UploadEndpointSelectionDialog> createState() =>
      _UploadEndpointSelectionDialogState();
}

class _UploadEndpointSelectionDialogState
    extends State<UploadEndpointSelectionDialog> {
  late final Set<String> _selectedNames;

  @override
  void initState() {
    super.initState();
    final availableNames = widget.endpoints.map((endpoint) => endpoint.name);
    _selectedNames = widget.initiallySelectedNames
        .where(availableNames.contains)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Data'),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.endpoints.isEmpty
            ? const Text('No upload sites configured')
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text('Select sites to upload to:'),
                    const SizedBox(height: 8),
                    ...widget.endpoints.map((endpoint) {
                      return CheckboxListTile(
                        key: ValueKey('upload-endpoint-${endpoint.name}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(endpoint.name),
                        subtitle: Text(
                          endpoint.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: _selectedNames.contains(endpoint.name),
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedNames.add(endpoint.name);
                            } else {
                              _selectedNames.remove(endpoint.name);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('upload-endpoint-cancel'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('upload-endpoint-submit'),
          onPressed: _selectedNames.isEmpty
              ? null
              : () {
                  final selectedNames = widget.endpoints
                      .where(
                        (endpoint) => _selectedNames.contains(endpoint.name),
                      )
                      .map((endpoint) => endpoint.name)
                      .toList();
                  Navigator.pop(context, selectedNames);
                },
          child: const Text('Upload'),
        ),
      ],
    );
  }
}
