import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/location_service.dart';
import 'package:path_provider/path_provider.dart';

/// Debug diagnostics screen for troubleshooting Samsung device issues
class DebugDiagnosticsScreen extends StatefulWidget {
  final LocationService locationService;

  const DebugDiagnosticsScreen({super.key, required this.locationService});

  @override
  State<DebugDiagnosticsScreen> createState() => _DebugDiagnosticsScreenState();
}

class _DebugDiagnosticsScreenState extends State<DebugDiagnosticsScreen> {
  List<File> _logFiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogFiles();
  }

  Future<void> _loadLogFiles() async {
    setState(() => _loading = true);

    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final files = directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.contains('meshcore_debug_'))
            .toList();

        // Sort by date (newest first)
        files.sort(
          (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
        );

        setState(() {
          _logFiles = files;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading log files: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _shareLogFile(File file) async {
    final l10n = AppLocalizations.of(context);
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: l10n.debugDiagnosticsShareSubject,
        text: l10n.debugDiagnosticsShareText,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.debugDiagnosticsErrorSharing('$e'))),
        );
      }
    }
  }

  Future<void> _deleteLogFile(File file) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.debugDiagnosticsDeleteTitle),
        content: Text(l10n.debugDiagnosticsDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.mapDelete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await file.delete();
        await _loadLogFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.debugDiagnosticsLogDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                ).debugDiagnosticsErrorDeleting('$e'),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _viewLogFile(File file) async {
    try {
      final content = await file.readAsString();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _LogViewerScreen(
              fileName: file.path.split('/').last,
              content: content,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).debugDiagnosticsErrorReading('$e'),
            ),
          ),
        );
      }
    }
  }

  String _formatFileSize(AppLocalizations l10n, int bytes) {
    if (bytes < 1024) return l10n.debugDiagnosticsSizeBytes(bytes);
    if (bytes < 1024 * 1024) {
      return l10n.debugDiagnosticsSizeKb((bytes / 1024).toStringAsFixed(1));
    }
    return l10n.debugDiagnosticsSizeMb(
      (bytes / (1024 * 1024)).toStringAsFixed(1),
    );
  }

  String _formatDateTime(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).toString();
    return '${DateFormat.yMMMd(locale).format(dt)} ${DateFormat.Hm(locale).format(dt)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsDebugDiagnostics),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogFiles,
            tooltip: l10n.debugDiagnosticsRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.debugDiagnosticsSamsungTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.debugDiagnosticsSamsungBody,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.debugDiagnosticsCurrentSession(
                          widget.locationService.debugLogPath
                                  ?.split('/')
                                  .last ??
                              l10n.debugDiagnosticsNotStarted,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _logFiles.isEmpty
                ? Center(
                    child: Text(
                      l10n.debugDiagnosticsEmpty,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _logFiles.length,
                    itemBuilder: (context, index) {
                      final file = _logFiles[index];
                      final fileName = file.path.split('/').last;
                      final fileSize = file.lengthSync();
                      final modified = file.lastModifiedSync();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.description,
                            color: Colors.blue,
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Text(
                            '${_formatFileSize(l10n, fileSize)} • ${_formatDateTime(context, modified)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'view':
                                  _viewLogFile(file);
                                  break;
                                case 'share':
                                  _shareLogFile(file);
                                  break;
                                case 'delete':
                                  _deleteLogFile(file);
                                  break;
                              }
                            },
                            itemBuilder: (context) {
                              final menuL10n = AppLocalizations.of(context);
                              return [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.visibility, size: 20),
                                      const SizedBox(width: 8),
                                      Text(menuL10n.debugDiagnosticsView),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.share, size: 20),
                                      const SizedBox(width: 8),
                                      Text(menuL10n.mapShare),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        menuL10n.mapDelete,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                          onTap: () => _viewLogFile(file),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Simple log file viewer
class _LogViewerScreen extends StatelessWidget {
  final String fileName;
  final String content;

  const _LogViewerScreen({required this.fileName, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(
                content,
                subject: AppLocalizations.of(
                  context,
                ).debugDiagnosticsShareSubjectWithFile(fileName),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          content,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
      ),
    );
  }
}
