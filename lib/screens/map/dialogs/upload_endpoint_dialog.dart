import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/upload_service.dart';

class UploadEndpointDialog extends StatefulWidget {
  const UploadEndpointDialog({this.existing, super.key});

  final UploadEndpoint? existing;

  @override
  State<UploadEndpointDialog> createState() => _UploadEndpointDialogState();
}

class _UploadEndpointDialogState extends State<UploadEndpointDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name);
    _urlController = TextEditingController(text: widget.existing?.url);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_isEditing ? l10n.mapEditUploadSite : l10n.mapAddUploadSite),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.mapSiteName,
              hintText: _isEditing ? null : l10n.mapSiteNameHint,
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: l10n.mapApiUrl,
              hintText: _isEditing
                  ? null
                  : 'https://your-site.pages.dev/api/samples',
            ),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.settingsCancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(_isEditing ? l10n.settingsSave : l10n.mapAdd),
        ),
      ],
    );
  }

  void _submit() {
    if (_nameController.text.isEmpty || _urlController.text.isEmpty) return;
    Navigator.pop(
      context,
      UploadEndpoint(name: _nameController.text, url: _urlController.text),
    );
  }
}

class CommunityCoverageEndpointDialog extends StatelessWidget {
  const CommunityCoverageEndpointDialog({required this.endpoints, super.key});

  final List<UploadEndpoint> endpoints;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SimpleDialog(
      title: Text(l10n.mapDownloadFrom),
      children: [
        for (final endpoint in endpoints)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, endpoint),
            child: Text(endpoint.name),
          ),
      ],
    );
  }
}

class UploadSitesConfiguration {
  UploadSitesConfiguration({
    required Iterable<UploadEndpoint> endpoints,
    required Iterable<String> selectedNames,
  }) : endpoints = List.unmodifiable(endpoints),
       selectedNames = List.unmodifiable(selectedNames);

  final List<UploadEndpoint> endpoints;
  final List<String> selectedNames;
}

class ManageUploadSitesSheet extends StatefulWidget {
  const ManageUploadSitesSheet({
    required this.initialEndpoints,
    required this.initiallySelectedNames,
    super.key,
  });

  final List<UploadEndpoint> initialEndpoints;
  final List<String> initiallySelectedNames;

  @override
  State<ManageUploadSitesSheet> createState() => _ManageUploadSitesSheetState();
}

class _ManageUploadSitesSheetState extends State<ManageUploadSitesSheet> {
  late final List<UploadEndpoint> _endpoints;
  late final Set<String> _selectedNames;

  @override
  void initState() {
    super.initState();
    _endpoints = List.of(widget.initialEndpoints);
    _selectedNames = Set.of(widget.initiallySelectedNames);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                l10n.settingsManageUploadSites,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.mapSelectWhichSitesToUpload,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              if (_endpoints.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(l10n.settingsUploadNoSites),
                )
              else
                for (final endpoint in _endpoints)
                  CheckboxListTile(
                    title: Text(endpoint.name),
                    subtitle: Text(
                      endpoint.url,
                      style: const TextStyle(fontSize: 11),
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
                    secondary: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.blue,
                          ),
                          onPressed: () => _edit(endpoint),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _delete(endpoint),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.mapAddSite),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.settingsCancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(
                      context,
                      UploadSitesConfiguration(
                        endpoints: _endpoints,
                        selectedNames: _selectedNames,
                      ),
                    ),
                    child: Text(l10n.settingsSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _add() async {
    final endpoint = await showDialog<UploadEndpoint>(
      context: context,
      builder: (context) => const UploadEndpointDialog(),
    );
    if (endpoint == null || !mounted) return;
    setState(() {
      _endpoints.add(endpoint);
      _selectedNames.add(endpoint.name);
    });
  }

  Future<void> _edit(UploadEndpoint existing) async {
    final endpoint = await showDialog<UploadEndpoint>(
      context: context,
      builder: (context) => UploadEndpointDialog(existing: existing),
    );
    if (endpoint == null || !mounted) return;
    final index = _endpoints.indexOf(existing);
    if (index == -1) return;
    setState(() {
      if (_selectedNames.remove(existing.name)) {
        _selectedNames.add(endpoint.name);
      }
      _endpoints[index] = endpoint;
    });
  }

  Future<void> _delete(UploadEndpoint endpoint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteUploadEndpointDialog(endpoint: endpoint),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _endpoints.remove(endpoint);
      _selectedNames.remove(endpoint.name);
    });
  }
}

class DeleteUploadEndpointDialog extends StatelessWidget {
  const DeleteUploadEndpointDialog({required this.endpoint, super.key});

  final UploadEndpoint endpoint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapDeleteSite),
      content: Text(l10n.mapDeleteSiteConfirm(endpoint.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.settingsCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(l10n.mapDelete),
        ),
      ],
    );
  }
}

class UploadProgressOutcome {
  const UploadProgressOutcome.success(this.results) : error = null;

  const UploadProgressOutcome.failure(this.error) : results = null;

  final Map<String, UploadResult>? results;
  final Object? error;
}

typedef UploadOperation = Future<Map<String, UploadResult>> Function(
  void Function(String siteName, int current, int total) onProgress,
);

class UploadProgressDialog extends StatefulWidget {
  const UploadProgressDialog({required this.upload, super.key});

  final UploadOperation upload;

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  int _currentBatch = 0;
  int _totalBatches = 0;
  String _currentSite = '';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final results = await widget.upload((siteName, current, total) {
        if (!mounted) return;
        setState(() {
          _currentSite = siteName;
          _currentBatch = current;
          _totalBatches = total;
        });
      });
      if (!mounted) return;
      Navigator.pop(context, UploadProgressOutcome.success(results));
    } catch (error) {
      if (!mounted) return;
      Navigator.pop(context, UploadProgressOutcome.failure(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _currentSite.isNotEmpty
                ? l10n.mapUploadingTo(_currentSite)
                : l10n.mapUploadingSamples,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_totalBatches > 1)
            Text(
              l10n.mapUploadBatch(_currentBatch, _totalBatches),
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class UploadResultsDialog extends StatelessWidget {
  const UploadResultsDialog({required this.results, super.key});

  final Map<String, UploadResult> results;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allSuccess = results.values.every((result) => result.success);
    final successCount = results.values
        .where((result) => result.success)
        .length;

    return AlertDialog(
      title: Text(allSuccess ? l10n.mapUploadComplete : l10n.mapUploadResults),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (results.length > 1)
            Text(l10n.mapUploadedToSites(successCount, results.length)),
          const SizedBox(height: 8),
          for (final entry in results.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    entry.value.success ? Icons.check_circle : Icons.error,
                    color: entry.value.success ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (!entry.value.success)
                          Text(
                            entry.value.message,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.mapOk),
        ),
      ],
    );
  }
}
