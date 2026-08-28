import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

/// Reasons a database backup file cannot be restored.
enum DatabaseBackupValidationError {
  /// The file is missing, unreadable, or not a SQLite database.
  invalidHeader,

  /// The database does not look like a MeshCore Wardrive database.
  missingTables,

  /// The backup was written by a newer app version.
  newerVersion,
}

/// Thrown when exporting or restoring the whole SQLite database fails.
class DatabaseBackupException implements Exception {
  const DatabaseBackupException(this.error);

  final DatabaseBackupValidationError error;

  @override
  String toString() => 'DatabaseBackupException(${error.name})';
}

/// Whole-database backup for [DatabaseService].
///
/// Unlike the JSON data export, this copies the raw SQLite file, so every
/// table (samples, sessions, uploads, planned markers, privacy zones,
/// impossible zones, devices, ducting cache) is preserved exactly as stored.
class DatabaseBackupService {
  DatabaseBackupService({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  final DatabaseService _databaseService;

  /// SQLite sidecar files that must not outlive their database.
  static const List<String> _sidecarSuffixes = ['-wal', '-shm', '-journal'];

  /// True when [bytes] starts with the SQLite 3 file signature.
  static bool hasSqliteHeader(List<int> bytes) {
    const magic = 'SQLite format 3\u0000';
    if (bytes.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic.codeUnitAt(i)) return false;
    }
    return true;
  }

  /// Exports the entire database into a new file at [targetPath].
  Future<File> exportToFile(String targetPath) async {
    final db = await _databaseService.database;
    final target = File(targetPath);
    await target.parent.create(recursive: true);
    if (await target.exists()) {
      await target.delete();
    }

    // Preferred: SQLite >= 3.27 snapshots the whole database consistently in a
    // single statement, even while other statements are writing.
    try {
      await db.execute('VACUUM INTO ?', [targetPath]);
      return target;
    } catch (e) {
      // Older SQLite builds (Android 9 and below) do not know VACUUM INTO.
      debugPrint('VACUUM INTO unavailable, falling back to file copy: $e');
    }

    // Fallback: flush write-ahead-log content into the main file first so the
    // plain copy captures every committed transaction.
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
    await File(db.path).copy(targetPath);
    return target;
  }

  /// Exports the database into the app cache directory and returns its bytes.
  ///
  /// The temporary snapshot file is removed after reading.
  Future<Uint8List> exportSnapshotBytes() async {
    final dir = await getTemporaryDirectory();
    final snapshot = await exportToFile(p.join(dir.path, 'database_backup.db'));
    try {
      return await snapshot.readAsBytes();
    } finally {
      if (await snapshot.exists()) {
        await snapshot.delete();
      }
    }
  }

  /// Exports the database to [documentsDirectory] under [fileName] and returns
  /// the written file, ready to be handed to the share sheet.
  Future<File> exportToShareFile(
    Directory documentsDirectory,
    String fileName,
  ) async {
    return exportToFile(p.join(documentsDirectory.path, fileName));
  }

  /// Checks that [backupPath] is a valid database backup of this app.
  ///
  /// Throws [DatabaseBackupException] when the file cannot be restored.
  Future<void> validateBackupFile(String backupPath) async {
    final file = File(backupPath);
    if (!await file.exists() || await file.length() < 100) {
      throw const DatabaseBackupException(
        DatabaseBackupValidationError.invalidHeader,
      );
    }

    final stream = file.openRead(0, 16);
    await for (final chunk in stream) {
      if (!hasSqliteHeader(chunk)) {
        throw const DatabaseBackupException(
          DatabaseBackupValidationError.invalidHeader,
        );
      }
      break;
    }

    Database? probe;
    try {
      // Read-only open never triggers schema creation or migrations.
      probe = await openDatabase(backupPath, readOnly: true);
      final versionRows = await probe.rawQuery('PRAGMA user_version');
      final version = Sqflite.firstIntValue(versionRows) ?? 0;
      if (version > DatabaseService.databaseVersion) {
        throw const DatabaseBackupException(
          DatabaseBackupValidationError.newerVersion,
        );
      }
      final tables = await probe.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = tables.map((row) => row['name'] as String?).toSet();
      if (!names.contains(DatabaseService.tableSamples)) {
        throw const DatabaseBackupException(
          DatabaseBackupValidationError.missingTables,
        );
      }
    } on DatabaseBackupException {
      rethrow;
    } catch (_) {
      // openDatabase on a corrupted or foreign SQLite file.
      throw const DatabaseBackupException(
        DatabaseBackupValidationError.invalidHeader,
      );
    } finally {
      await probe?.close();
    }
  }

  /// Replaces the live database with the backup at [backupPath].
  ///
  /// The current database is kept aside until the restored copy has been
  /// reopened successfully, so a failed restore cannot leave the app without
  /// a working database.
  Future<void> restoreFromFile(String backupPath) async {
    await validateBackupFile(backupPath);

    final livePath = (await _databaseService.database).path;
    await _databaseService.close();

    final target = File(livePath);
    final staged = File('$livePath.restore-tmp');
    final previous = File('$livePath.pre-restore');
    await _deleteIfExists(staged);
    await _deleteIfExists(previous);

    // Stage the new file on the same filesystem so the final swap is atomic.
    await File(backupPath).copy(staged.path);

    // Stale sidecars would mix pre-restore WAL content into the new database.
    for (final suffix in _sidecarSuffixes) {
      await _deleteIfExists(File('$livePath$suffix'));
    }
    if (await target.exists()) {
      await target.rename(previous.path);
    }
    await staged.rename(target.path);

    try {
      // Reopening runs schema upgrades for backups from older app versions.
      await _databaseService.database;
    } catch (e) {
      // Roll the previous database back so the app keeps working.
      debugPrint('Restored database failed to open, rolling back: $e');
      await _deleteIfExists(target);
      if (await previous.exists()) {
        await previous.rename(target.path);
        await _databaseService.database;
      }
      rethrow;
    } finally {
      await _deleteIfExists(previous);
    }
  }

  static Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
