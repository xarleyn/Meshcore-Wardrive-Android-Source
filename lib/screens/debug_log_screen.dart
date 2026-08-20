import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/debug_log_service.dart';

class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  final DebugLogService _logService = DebugLogService();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<LogEntry>? _logSubscription;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();

    // Scroll to bottom when screen first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _logService.logs.isNotEmpty) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    // Listen for new log entries and auto-scroll
    _logSubscription = _logService.logStream.listen((entry) {
      if (_autoScroll && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.success:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  Future<void> _exportLogs() async {
    final l10n = AppLocalizations.of(context);
    try {
      final logs = _logService.logs;
      if (logs.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.debugLogNoLogsToExport)));
        return;
      }

      // Build log content
      final buffer = StringBuffer();
      for (final log in logs) {
        final category = log.category != null ? '[${log.category}] ' : '';
        buffer.writeln('[${log.formattedTime}] $category${log.message}');
      }

      // Generate filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'meshcore_wardrive_log_$timestamp.txt';

      // Let user choose directory
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.debugLogChooseSaveLocation,
      );

      if (selectedDirectory == null) {
        // User cancelled
        return;
      }

      // Save file to chosen directory
      final file = File('$selectedDirectory/$fileName');
      await file.writeAsString(buffer.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.debugLogSavedTo(fileName)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).mapExportFailed('$e')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final logs = _logService.logs;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapDebugTerminal),
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.arrow_downward
                  : Icons.arrow_downward_outlined,
            ),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
            tooltip: _autoScroll
                ? l10n.debugLogAutoScrollOn
                : l10n.debugLogAutoScrollOff,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _exportLogs,
            tooltip: l10n.debugLogExportLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _logService.clear();
              setState(() {});
            },
            tooltip: l10n.debugLogClearLogs,
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: logs.isEmpty
            ? Center(
                child: Text(
                  l10n.debugLogEmpty,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: logs.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final color = _getColorForLevel(log.level);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timestamp
                        Text(
                          '${log.formattedTime} ',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        // Category badge
                        if (log.category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              log.category!,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Message
                        Expanded(
                          child: Text(
                            log.message,
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
