import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../utils/distance_units.dart';

TextStyle sessionMapHintStyle(BuildContext context) {
  return TextStyle(
    color: Theme.of(context).colorScheme.primary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}

class SessionHistoryScreen extends StatefulWidget {
  /// Optional callback when a session is selected (for map filtering)
  final void Function(WSession session)? onSessionSelected;

  /// Called after a session row is deleted, with remaining sessions newest first.
  final void Function(int deletedId, List<WSession> remaining)?
  onSessionDeleted;

  const SessionHistoryScreen({
    super.key,
    this.onSessionSelected,
    this.onSessionDeleted,
  });

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final SettingsService _settings = SettingsService();
  List<WSession> _sessions = [];
  bool _loading = true;
  String _distanceUnit = 'km';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _dbService.getAllSessions();
    final unit = await _settings.getDistanceUnit();
    setState(() {
      _sessions = sessions;
      _distanceUnit = unit;
      _loading = false;
    });
  }

  String _formatDuration(AppLocalizations l10n, Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return l10n.sessionDurationHoursMinutes(hours, minutes);
    } else if (minutes > 0) {
      return l10n.sessionDurationMinutesSeconds(minutes, seconds);
    }
    return l10n.sessionDurationSeconds(seconds);
  }

  String _formatDistance(AppLocalizations l10n, double meters) {
    if (_distanceUnit == 'km') {
      final km = meters / 1000.0;
      return l10n.sessionDistanceKm(km.toStringAsFixed(1));
    } else {
      final miles = meters / DistanceUnits.metersPerMile;
      return l10n.sessionDistanceMi(miles.toStringAsFixed(1));
    }
  }

  Future<void> _deleteSession(WSession session) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sessionDeleteTitle),
        content: Text(l10n.sessionDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.mapDelete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && session.id != null) {
      await _dbService.deleteSession(session.id!);
      await _loadSessions();
      widget.onSessionDeleted?.call(session.id!, _sessions);
    }
  }

  Future<void> _editNotes(WSession session) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: session.notes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sessionNotesTitle),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.sessionNotesHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.settingsSave),
          ),
        ],
      ),
    );

    if (result != null) {
      final updated = WSession(
        id: session.id,
        startTime: session.startTime,
        endTime: session.endTime,
        distanceMeters: session.distanceMeters,
        sampleCount: session.sampleCount,
        pingCount: session.pingCount,
        successCount: session.successCount,
        notes: result.isEmpty ? null : result,
      );
      await _dbService.updateSession(updated);
      await _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSessionHistory)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
          ? Center(
              child: Text(
                l10n.sessionEmpty,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _sessions.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return _buildSessionCard(session);
              },
            ),
    );
  }

  Widget _buildSessionCard(WSession session) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale);
    final timeFormat = DateFormat.jm(locale);
    final duration = session.duration;
    final successRate = session.successRate;

    // Determine status color based on success rate
    Color statusColor;
    if (session.pingCount == 0) {
      statusColor = Colors.grey;
    } else if (successRate >= 70) {
      statusColor = Colors.green;
    } else if (successRate >= 30) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: widget.onSessionSelected != null
            ? () {
                widget.onSessionSelected!(session);
                Navigator.pop(context);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: date + actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(session.startTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.note_add, size: 20),
                        onPressed: () => _editNotes(session),
                        tooltip: l10n.sessionEditNotes,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteSession(session),
                        tooltip: l10n.mapDelete,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),

              // Time range
              Text(
                session.endTime != null
                    ? l10n.sessionTimeRange(
                        timeFormat.format(session.startTime),
                        timeFormat.format(session.endTime!),
                      )
                    : l10n.sessionTimeInProgress(
                        timeFormat.format(session.startTime),
                      ),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),

              const SizedBox(height: 8),

              // Stats row
              Row(
                children: [
                  _buildStat(
                    Icons.timer,
                    duration != null ? _formatDuration(l10n, duration) : '--',
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    Icons.straighten,
                    _formatDistance(l10n, session.distanceMeters),
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    Icons.location_on,
                    l10n.sessionPoints(session.sampleCount),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Ping stats row
              Row(
                children: [
                  _buildStat(
                    Icons.cell_tower,
                    l10n.analyticsPingsCount(session.pingCount),
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    Icons.check_circle,
                    l10n.sessionHeard(session.successCount),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  if (session.pingCount > 0)
                    _buildStat(
                      Icons.percent,
                      '${successRate.toStringAsFixed(0)}%',
                      color: statusColor,
                    ),
                ],
              ),

              // Notes
              if (session.notes != null && session.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  session.notes!,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Tap hint when callback is provided
              if (widget.onSessionSelected != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.sessionTapToViewOnMap,
                  style: sessionMapHintStyle(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: color ?? Colors.grey[600]),
        ),
      ],
    );
  }
}
