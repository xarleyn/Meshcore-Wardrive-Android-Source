import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'settings_service.dart';

class Achievement {
  final String id;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.icon,
    this.unlocked = false,
    this.unlockedAt,
  });
}

class AchievementService {
  static final AchievementService _instance = AchievementService._();
  factory AchievementService() => _instance;
  AchievementService._();

  final _unlockController = StreamController<Achievement>.broadcast();
  Stream<Achievement> get unlockStream => _unlockController.stream;

  static const _prefix = 'achievement_';

  // Achievement definitions. Titles and descriptions live in ARB / l10n.
  static final List<Map<String, String>> _definitions = [
    {'id': 'first_ping', 'icon': '📡'},
    {'id': 'pings_100', 'icon': '💯'},
    {'id': 'pings_1000', 'icon': '🔥'},
    {'id': 'pings_10000', 'icon': '👑'},
    {'id': 'first_repeater', 'icon': '📻'},
    {'id': 'repeaters_10', 'icon': '🗺️'},
    {'id': 'repeaters_50', 'icon': '🌐'},
    {'id': 'miles_10', 'icon': '🚗'},
    {'id': 'miles_100', 'icon': '🛣️'},
    {'id': 'miles_500', 'icon': '✈️'},
    {'id': 'cells_50', 'icon': '🏘️'},
    {'id': 'cells_500', 'icon': '🏰'},
    {'id': 'first_session', 'icon': '🎬'},
    {'id': 'sessions_50', 'icon': '🏆'},
  ];

  /// Get all achievements with their unlock status
  Future<List<Achievement>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _definitions.map((d) {
      final key = '$_prefix${d['id']}';
      final unlockedMs = prefs.getInt(key);
      return Achievement(
        id: d['id']!,
        icon: d['icon']!,
        unlocked: unlockedMs != null,
        unlockedAt: unlockedMs != null
            ? DateTime.fromMillisecondsSinceEpoch(unlockedMs)
            : null,
      );
    }).toList();
  }

  /// Check and unlock achievements based on current stats
  Future<List<Achievement>> checkAndUnlock() async {
    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseService();
    final settings = SettingsService();
    final newlyUnlocked = <Achievement>[];

    // Gather stats
    final samples = await db.getAllSamples();
    final pings = samples.where((s) => s.pingSuccess != null).length;
    final sessions = await db.getAllSessions();
    final totalMiles = (await settings.getTotalDistanceDriven()) / 1609.34;

    // Unique repeaters
    final repeaterIds = <String>{};
    for (final s in samples) {
      if (s.path != null && s.path!.isNotEmpty) repeaterIds.add(s.path!);
    }

    // Unique cells
    final cells = <String>{};
    for (final s in samples) {
      if (s.pingSuccess != null) {
        // Use first 6 chars of geohash as coverage key (precision 6)
        cells.add(
          s.geohash.substring(0, s.geohash.length >= 6 ? 6 : s.geohash.length),
        );
      }
    }

    // Check thresholds
    final checks = <String, bool>{
      'first_ping': pings >= 1,
      'pings_100': pings >= 100,
      'pings_1000': pings >= 1000,
      'pings_10000': pings >= 10000,
      'first_repeater': repeaterIds.isNotEmpty,
      'repeaters_10': repeaterIds.length >= 10,
      'repeaters_50': repeaterIds.length >= 50,
      'miles_10': totalMiles >= 10,
      'miles_100': totalMiles >= 100,
      'miles_500': totalMiles >= 500,
      'cells_50': cells.length >= 50,
      'cells_500': cells.length >= 500,
      'first_session': sessions.isNotEmpty,
      'sessions_50': sessions.length >= 50,
    };

    for (final entry in checks.entries) {
      final key = '$_prefix${entry.key}';
      if (entry.value && prefs.getInt(key) == null) {
        final now = DateTime.now();
        await prefs.setInt(key, now.millisecondsSinceEpoch);
        final def = _definitions.firstWhere((d) => d['id'] == entry.key);
        final achievement = Achievement(
          id: entry.key,
          icon: def['icon']!,
          unlocked: true,
          unlockedAt: now,
        );
        newlyUnlocked.add(achievement);
        _unlockController.add(achievement);
      }
    }

    return newlyUnlocked;
  }

  void dispose() {
    _unlockController.close();
  }
}
