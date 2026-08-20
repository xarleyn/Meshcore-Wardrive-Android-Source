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
