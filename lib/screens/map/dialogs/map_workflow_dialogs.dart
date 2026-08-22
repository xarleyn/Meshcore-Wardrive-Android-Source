import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

enum SampleExportFormat {
  json('json'),
  csv('csv'),
  gpx('gpx'),
  kml('kml');

  const SampleExportFormat(this.extension);

  final String extension;

  String get displayName => extension.toUpperCase();
}

enum ExportDestination { save, share }

class ContinueRequestDialog extends StatelessWidget {
  const ContinueRequestDialog({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.mapNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.mapContinue),
        ),
      ],
    );
  }
}

class OpenSettingsDialog extends StatelessWidget {
  const OpenSettingsDialog({
    required this.title,
    required this.message,
    required this.actionLabel,
    super.key,
  });

  final String title;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.mapNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class SaveEmptySessionDialog extends StatelessWidget {
  const SaveEmptySessionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapSessionEmptyTitle),
      content: Text(l10n.mapSessionEmptyBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.mapDontSave),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.settingsSave),
        ),
      ],
    );
  }
}

class ClearMapHistoryDialog extends StatelessWidget {
  const ClearMapHistoryDialog({required this.sampleCount, super.key});

  final int sampleCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapClearMapHistoryTitle),
      content: Text(
        l10n.mapClearMapHistoryBody(sampleCount),
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.settingsCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(l10n.mapDeleteAll),
        ),
      ],
    );
  }
}

class SampleExportFormatDialog extends StatelessWidget {
  const SampleExportFormatDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapExportFormat),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _formatTile(
            context,
            format: SampleExportFormat.json,
            icon: Icons.code,
            subtitle: l10n.mapExportJsonSubtitle,
          ),
          _formatTile(
            context,
            format: SampleExportFormat.csv,
            icon: Icons.table_chart,
            subtitle: l10n.mapExportCsvSubtitle,
          ),
          _formatTile(
            context,
            format: SampleExportFormat.gpx,
            icon: Icons.route,
            subtitle: l10n.mapExportGpxSubtitle,
          ),
          _formatTile(
            context,
            format: SampleExportFormat.kml,
            icon: Icons.map,
            subtitle: l10n.mapExportKmlSubtitle,
          ),
        ],
      ),
    );
  }

  Widget _formatTile(
    BuildContext context, {
    required SampleExportFormat format,
    required IconData icon,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(format.displayName),
      subtitle: Text(subtitle),
      onTap: () => Navigator.pop(context, format),
    );
  }
}

class ExportDestinationDialog extends StatelessWidget {
  const ExportDestinationDialog({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(title),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ExportDestination.save),
          child: Text(l10n.mapSaveToFolder),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ExportDestination.share),
          child: Text(l10n.mapShare),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.settingsCancel),
        ),
      ],
    );
  }
}

class ImportSettingsConfirmationDialog extends StatelessWidget {
  const ImportSettingsConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.settingsImportSettings),
      content: Text(l10n.mapImportSettingsConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.settingsCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.mapImport),
        ),
      ],
    );
  }
}

class UpdateAvailableDialog extends StatelessWidget {
  const UpdateAvailableDialog({
    required this.latestVersion,
    required this.currentVersion,
    super.key,
  });

  final String latestVersion;
  final String currentVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapUpdateAvailable),
      content: Text(l10n.mapUpdateAvailableBody(latestVersion, currentVersion)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.compassLater),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.mapDownload),
        ),
      ],
    );
  }
}

class ShareScreenshotDialog extends StatelessWidget {
  const ShareScreenshotDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapScreenshotSavedTitle),
      content: Text(l10n.mapShareScreenshotPrompt),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.mapNo),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.mapYes),
        ),
      ],
    );
  }
}
