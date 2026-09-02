import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../../services/database_backup_service.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/settings_service.dart';
import '../../utils/sample_export.dart';
import 'dialogs/map_workflow_dialogs.dart';

/// Data and settings import/export orchestration for the map screen.
///
/// The class owns no state: the caller passes the owning screen's [context]
/// for localization, dialogs, and mounted checks, services for persistence,
/// and callbacks for everything that belongs to the screen (snackbars,
/// cache invalidation, and reloads of screen-owned data). Serialization of
/// sample exports stays in `SampleExport`; this class only orchestrates
/// pickers, sharing, dialogs, and the database.
class MapDataIo {
  const MapDataIo({
    required this.context,
    required this.onShowSnackBar,
    required this.locationService,
    required this.databaseService,
    required this.databaseBackupService,
    required this.settingsService,
    required this.isTracking,
    required this.sampleCount,
    required this.repeaters,
    required this.invalidateCaches,
    required this.loadSamples,
    required this.loadSettings,
    required this.onDatabaseRestored,
    required this.loadMarkers,
    required this.loadPrivacyZones,
    required this.loadImpossibleZones,
  });

  /// Screen context used for mounted checks, localization, and dialogs.
  final BuildContext context;

  /// Shows a transient message; the owner guards this callback with its own
  /// mounted check.
  final void Function(String message) onShowSnackBar;

  final LocationService locationService;
  final DatabaseService databaseService;
  final DatabaseBackupService databaseBackupService;
  final SettingsService settingsService;

  /// Current tracking state; import of a database backup is refused while
  /// tracking is active.
  final bool Function() isTracking;

  /// Current sample count, shown in the clear-history confirmation and in its
  /// completion snackbar.
  final int Function() sampleCount;

  /// Current repeater contacts included in JSON data exports.
  final List<Repeater> Function() repeaters;

  /// Drops screen-owned derived caches after data changes.
  final VoidCallback invalidateCaches;

  /// Reloads samples after data or settings changes.
  final Future<void> Function() loadSamples;

  /// Reloads applied settings after a settings import.
  final Future<void> Function() loadSettings;

  /// Resets the session map view after a database restore.
  final VoidCallback onDatabaseRestored;

  final Future<void> Function() loadMarkers;
  final Future<void> Function() loadPrivacyZones;
  final Future<void> Function() loadImpossibleZones;

  /// Clears all samples after a confirmation dialog.
  Future<void> clearData() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          ClearMapHistoryDialog(sampleCount: sampleCount()),
    );

    if (confirmed == true) {
      await locationService.clearAllSamples();
      await loadSamples();
      onShowSnackBar(l10n.mapDeletedSamples(sampleCount()));
    }
  }

  /// Exports all samples in the selected format, saving to a file or sharing.
  Future<void> exportData() async {
    // Ask user for export format
    final format = await showDialog<SampleExportFormat>(
      context: context,
      builder: (dialogContext) => const SampleExportFormatDialog(),
    );

    if (format == null) return;

    // Ask save or share
    if (!context.mounted) return;
    final choice = await showDialog<ExportDestination>(
      context: context,
      builder: (dialogContext) => ExportDestinationDialog(
        title: AppLocalizations.of(context).mapExportAs(format.displayName),
      ),
    );

    if (choice == null) return;

    try {
      final samples = await locationService.getAllSamples();
      // Privacy-zone samples never leave the device through file exports;
      // only the full database backup keeps them.
      final exportSamples = await databaseService.filterByPrivacyZones(samples);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String content;
      String fileName;
      String extension;

      switch (format) {
        case SampleExportFormat.csv:
          content = SampleExport.buildCsv(exportSamples);
          extension = 'csv';
          fileName = 'meshcore_export_$timestamp.csv';
          break;
        case SampleExportFormat.gpx:
          content = SampleExport.buildGpx(exportSamples);
          extension = 'gpx';
          fileName = 'meshcore_export_$timestamp.gpx';
          break;
        case SampleExportFormat.kml:
          content = SampleExport.buildKml(exportSamples);
          extension = 'kml';
          fileName = 'meshcore_export_$timestamp.kml';
          break;
        case SampleExportFormat.json:
          // Include discovered repeater contacts in the export
          final repeaterJsonList = repeaters()
              .where(
                (r) =>
                    r.position.latitude != 0.0 || r.position.longitude != 0.0,
              )
              .map((r) => r.toJson())
              .toList();
          final data = await databaseService.exportAllData(
            repeaters: repeaterJsonList,
          );
          content = jsonEncode(data);
          extension = 'json';
          fileName = 'meshcore_export_$timestamp.json';
      }

      if (choice == ExportDestination.save) {
        if (!context.mounted) return;
        await FilePicker.platform.saveFile(
          dialogTitle: AppLocalizations.of(context).mapSaveExport,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: [extension],
          bytes: utf8.encode(content),
        );
        if (!context.mounted) return;
        onShowSnackBar(
          AppLocalizations.of(context)
              .mapExportedSamples(exportSamples.length, format.displayName),
        );
      } else if (choice == ExportDestination.share) {
        final directory = await getExternalStorageDirectory();
        final file = File('${directory!.path}/$fileName');
        await file.writeAsString(content);

        if (!context.mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: AppLocalizations.of(context).mapExportShareSubject,
            text: AppLocalizations.of(context)
                .mapExportShareText(exportSamples.length),
          ),
        );
        if (!context.mounted) return;
        onShowSnackBar(AppLocalizations.of(context).mapExportShared);
      }
    } catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapExportFailed('$e'));
    }
  }

  /// Imports sample/session JSON files, merging multiple picks.
  Future<void> importData() async {
    try {
      // Pick JSON file(s) — allow multiple for community merge
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      int totalSamplesImported = 0;
      int totalSessionsImported = 0;
      final Set<String> sources = {};

      for (final pickedFile in result.files) {
        if (pickedFile.path == null) continue;
        final file = File(pickedFile.path!);
        final jsonString = await file.readAsString();
        final dynamic jsonData = jsonDecode(jsonString);

        // Use unified import that handles both old (array) and new (object) formats
        final counts = await databaseService.importAllData(jsonData);
        totalSamplesImported += counts['samples'] ?? 0;
        totalSessionsImported += counts['sessions'] ?? 0;

        // Extract sources for display
        if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('samples')) {
          for (final s in (jsonData['samples'] as List<dynamic>)) {
            final map = s as Map<String, dynamic>;
            if (map['source'] != null) sources.add(map['source'] as String);
          }
        } else if (jsonData is List) {
          for (final s in jsonData) {
            final map = s as Map<String, dynamic>;
            if (map['source'] != null) sources.add(map['source'] as String);
          }
        }
      }

      // Reload map
      invalidateCaches();
      await loadSamples();

      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context);
      final sessionLabel = totalSessionsImported > 0
          ? l10n.mapImportedSessionsSuffix(totalSessionsImported)
          : '';
      final sourceLabel = sources.isNotEmpty
          ? l10n.mapImportedFromSources(sources.join(', '))
          : '';
      onShowSnackBar(
        '${l10n.mapImportedSamples(totalSamplesImported)}$sessionLabel$sourceLabel',
      );
    } catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapImportFailed('$e'));
    }
  }

  /// Exports settings JSON to a file or via the share sheet.
  Future<void> exportSettings() async {
    try {
      final jsonString = await settingsService.exportSettingsJson();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'meshcore_settings_$timestamp.json';

      // Ask save or share
      if (!context.mounted) return;
      final choice = await showDialog<ExportDestination>(
        context: context,
        builder: (dialogContext) => ExportDestinationDialog(
          title: AppLocalizations.of(context).settingsExportSettings,
        ),
      );

      if (choice == null) return;

      if (choice == ExportDestination.save) {
        if (!context.mounted) return;
        await FilePicker.platform.saveFile(
          dialogTitle: AppLocalizations.of(context).mapSaveSettings,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: utf8.encode(jsonString),
        );
        if (!context.mounted) return;
        onShowSnackBar(AppLocalizations.of(context).mapSettingsExported);
      } else if (choice == ExportDestination.share) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(jsonString);
        if (!context.mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: AppLocalizations.of(context).mapSettingsShareText,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapExportFailed('$e'));
    }
  }

  /// Imports settings JSON after a confirmation dialog and applies it.
  Future<void> importSettings() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;
      final pickedFile = result.files.single;

      final file = File(pickedFile.path!);
      final jsonString = await file.readAsString();

      // Show confirmation dialog
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => const ImportSettingsConfirmationDialog(),
      );

      if (confirmed != true) return;

      final applied = await settingsService.importSettingsJson(jsonString);

      // Reload settings to apply changes
      await loadSettings();
      invalidateCaches();
      await loadSamples();

      if (!context.mounted) return;
      onShowSnackBar(
        AppLocalizations.of(context).mapImportedSettingsCount(applied),
      );
    } on FormatException catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(
        AppLocalizations.of(context).mapInvalidSettingsFile(e.message),
      );
    } catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapImportFailed('$e'));
    }
  }

  /// Exports a database backup snapshot to a file or via the share sheet.
  Future<void> exportDatabase() async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'meshcore_backup_$timestamp.db';

      if (!context.mounted) return;
      final choice = await showDialog<ExportDestination>(
        context: context,
        builder: (dialogContext) => ExportDestinationDialog(
          title: AppLocalizations.of(context).settingsExportDatabase,
        ),
      );

      if (choice == null) return;

      if (choice == ExportDestination.save) {
        final bytes = await databaseBackupService.exportSnapshotBytes();
        if (!context.mounted) return;
        await FilePicker.platform.saveFile(
          dialogTitle: AppLocalizations.of(context).mapSaveExport,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['db'],
          bytes: bytes,
        );
        if (!context.mounted) return;
        onShowSnackBar(AppLocalizations.of(context).settingsDatabaseExported);
      } else if (choice == ExportDestination.share) {
        final dir = await getApplicationDocumentsDirectory();
        final file = await databaseBackupService.exportToShareFile(
          dir,
          fileName,
        );
        if (!context.mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: AppLocalizations.of(context).settingsExportDatabase,
            text: AppLocalizations.of(context).settingsDatabaseShareText,
          ),
        );
        if (!context.mounted) return;
        onShowSnackBar(AppLocalizations.of(context).mapExportShared);
      }
    } catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapExportFailed('$e'));
    }
  }

  /// Restores a database backup after validation and confirmation, then
  /// reloads everything derived from the database.
  Future<void> importDatabase() async {
    final l10n = AppLocalizations.of(context);
    if (isTracking()) {
      onShowSnackBar(l10n.settingsImportDatabaseStopTracking);
      return;
    }

    try {
      // FileType.custom with ['db'] is unusable on Android: '.db' has no MIME
      // mapping there, so the picker greys the backup out and it cannot be
      // selected. Accept any file instead and rely on validateBackupFile
      // below to reject non-backup contents with a clear error.
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.isEmpty) return;
      final backupPath = result.files.single.path;
      if (backupPath == null) return;

      // Validate before destroying anything.
      await databaseBackupService.validateBackupFile(backupPath);

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => const ImportDatabaseConfirmationDialog(),
      );
      if (confirmed != true) return;

      await databaseBackupService.restoreFromFile(backupPath);

      // Reload everything that is derived from the database.
      onDatabaseRestored();
      invalidateCaches();
      await loadSamples();
      await loadMarkers();
      await loadPrivacyZones();
      await loadImpossibleZones();

      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).settingsDatabaseImported);
    } on DatabaseBackupException catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(switch (e.error) {
        DatabaseBackupValidationError.newerVersion => AppLocalizations.of(
          context,
        ).settingsDatabaseNewerVersion,
        _ => AppLocalizations.of(context).settingsDatabaseInvalidFile,
      });
    } catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapImportFailed('$e'));
    }
  }
}
