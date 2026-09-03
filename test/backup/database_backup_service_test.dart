import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/services/database_backup_service.dart';
import 'package:meshcore_wardrive/services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_path_provider.dart';
import '../helpers/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useSqfliteFfi();

  group('DatabaseBackupService.hasSqliteHeader', () {
    test('accepts the SQLite 3 signature', () {
      final bytes = <int>[...'SQLite format 3\u0000'.codeUnits, 1, 2, 3];
      expect(DatabaseBackupService.hasSqliteHeader(bytes), isTrue);
    });

    test('rejects empty and short content', () {
      expect(DatabaseBackupService.hasSqliteHeader(<int>[]), isFalse);
      expect(DatabaseBackupService.hasSqliteHeader(<int>[0x53, 0x51]), isFalse);
    });

    test('rejects foreign file signatures', () {
      expect(
        DatabaseBackupService.hasSqliteHeader(<int>[
          ...'PK\u0003\u0004'.codeUnits,
        ]),
        isFalse,
      );
      expect(
        DatabaseBackupService.hasSqliteHeader(<int>[
          ...'not a database'.codeUnits,
        ]),
        isFalse,
      );
    });
  });

  group('DatabaseBackupService.validateBackupFile', () {
    late Directory tempDir;
    final service = DatabaseBackupService();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('db_backup_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Matcher throwsInvalidHeader() => throwsA(
      isA<DatabaseBackupException>().having(
        (e) => e.error,
        'error',
        DatabaseBackupValidationError.invalidHeader,
      ),
    );

    test('rejects a missing file', () {
      expect(
        service.validateBackupFile('${tempDir.path}/missing.db'),
        throwsInvalidHeader(),
      );
    });

    test('rejects a non-SQLite file', () async {
      final file = File('${tempDir.path}/garbage.db');
      await file.writeAsString('not a database at all ' * 10);

      expect(service.validateBackupFile(file.path), throwsInvalidHeader());
    });

    test('rejects a file that only fakes the SQLite signature', () async {
      // Carries the magic header but is not a database a plugin can open.
      final file = File('${tempDir.path}/fake.db');
      await file.writeAsBytes(<int>[
        ...'SQLite format 3\u0000'.codeUnits,
        ...List<int>.filled(200, 0),
      ]);

      expect(service.validateBackupFile(file.path), throwsInvalidHeader());
    });

    test('rejects a database written by a newer app version', () async {
      final path = '${tempDir.path}/newer.db';
      final db = await databaseFactoryFfi.openDatabase(path);
      await db.execute('CREATE TABLE samples (id TEXT PRIMARY KEY)');
      await db.execute(
        'PRAGMA user_version = ${DatabaseService.databaseVersion + 1}',
      );
      await db.close();

      expect(
        service.validateBackupFile(path),
        throwsA(
          isA<DatabaseBackupException>().having(
            (e) => e.error,
            'error',
            DatabaseBackupValidationError.newerVersion,
          ),
        ),
      );
    });

    test('rejects a database without the samples table', () async {
      final path = '${tempDir.path}/foreign.db';
      final db = await databaseFactoryFfi.openDatabase(path);
      await db.execute('CREATE TABLE something_else (id INTEGER)');
      await db.close();

      expect(
        service.validateBackupFile(path),
        throwsA(
          isA<DatabaseBackupException>().having(
            (e) => e.error,
            'error',
            DatabaseBackupValidationError.missingTables,
          ),
        ),
      );
    });
  });

  group('DatabaseBackupService export and restore', () {
    late Directory tempDir;
    late DatabaseService databaseService;
    late DatabaseBackupService backupService;
    late String backupPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('db_backup_roundtrip');
      installFakePathProvider(tempDir);
      databaseService = DatabaseService();
      backupService = DatabaseBackupService(databaseService: databaseService);
      backupPath = p.join(tempDir.path, 'backup.db');
      await _seedDemoData(databaseService);
    });

    tearDown(() async {
      try {
        await databaseService.close();
      } catch (_) {
        // The database may already be closed or failed to open; deleting the
        // directory is best-effort either way.
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'exportToFile writes a complete backup that passes validation',
      () async {
        final target = File(p.join(tempDir.path, 'out', 'exported.db'));
        await backupService.exportToFile(target.path);

        expect(await target.exists(), isTrue);
        expect(
          DatabaseBackupService.hasSqliteHeader(await target.readAsBytes()),
          isTrue,
        );
        await backupService.validateBackupFile(target.path);

        final probe = await openDatabase(target.path, readOnly: true);
        try {
          expect(
            Sqflite.firstIntValue(
              await probe.rawQuery('SELECT COUNT(*) FROM samples'),
            ),
            3,
          );
          expect(
            Sqflite.firstIntValue(
              await probe.rawQuery('SELECT COUNT(*) FROM sessions'),
            ),
            1,
          );
          expect(
            Sqflite.firstIntValue(
              await probe.rawQuery('SELECT COUNT(*) FROM uploads'),
            ),
            1,
          );
        } finally {
          await probe.close();
        }
      },
    );

    test(
      'exportSnapshotBytes returns SQLite bytes and cleans up its file',
      () async {
        final bytes = await backupService.exportSnapshotBytes();

        expect(DatabaseBackupService.hasSqliteHeader(bytes), isTrue);
        expect(
          File(p.join(tempDir.path, 'database_backup.db')).existsSync(),
          isFalse,
          reason: 'the temporary snapshot must not survive the export',
        );
      },
    );

    test(
      'exportToShareFile writes the backup under the requested name',
      () async {
        final file = await backupService.exportToShareFile(tempDir, 'share.db');

        expect(file.path, p.join(tempDir.path, 'share.db'));
        expect(await file.exists(), isTrue);
        expect(
          DatabaseBackupService.hasSqliteHeader(await file.readAsBytes()),
          isTrue,
        );
      },
    );

    test('restore replaces live data with the backup content', () async {
      await backupService.exportToFile(backupPath);

      // Mutate the live database so the restore has something to undo:
      // wipe samples and plant an extra marker that the backup lacks.
      await databaseService.deleteAllSamples();
      await databaseService.addMarker(10.0, 20.0, 'extra marker');
      expect(await databaseService.getSampleCount(), 0);

      await backupService.restoreFromFile(backupPath);

      final samples = await databaseService.getAllSamples();
      expect(samples.map((s) => s.id), unorderedEquals(['s1', 's2', 's3']));
      final s2 = samples.singleWhere((s) => s.id == 's2');
      expect(s2.position.latitude, 55.2);
      expect(s2.rssi, -90);
      expect(s2.snr, 5);
      expect(s2.pingSuccess, isTrue);
      expect(s2.responseTimeMs, 320);
      expect(s2.ductingRisk, 'possible');
      expect(s2.source, 'unit-a');
      expect(s2.deviceId, 'pk1');

      final session = (await databaseService.getAllSessions()).single;
      expect(session.sampleCount, 3);
      expect(session.pingCount, 2);
      expect(session.successCount, 1);
      expect(session.notes, 'seed');

      // The marker added after the export must be gone again.
      final markers = await databaseService.getAllMarkers();
      expect(markers, hasLength(1));
      expect(markers.single['label'], 'planned repeater');

      expect(
        (await databaseService.getAllPrivacyZones()).single['label'],
        'home',
      );
      expect(
        (await databaseService.getAllImpossibleZones()).single.label,
        'sea',
      );
      expect(
        (await databaseService.getAllDevices()).single['public_key'],
        'pk1',
      );

      // Per-endpoint upload state survives the restore.
      final pending = await databaseService.getUnuploadedSamplesForEndpoint(
        'https://example.org/api',
      );
      expect(pending.map((s) => s.id), unorderedEquals(['s2', 's3']));
    });

    test('restore refuses a non-database file and keeps live data', () async {
      final garbage = File(p.join(tempDir.path, 'garbage.db'));
      await garbage.writeAsString('definitely not a database ' * 20);

      await expectLater(
        backupService.restoreFromFile(garbage.path),
        throwsA(isA<DatabaseBackupException>()),
      );
      expect(await databaseService.getSampleCount(), 3);
    });

    test('restore refuses a backup from a newer app version', () async {
      final newerPath = p.join(tempDir.path, 'newer.db');
      final db = await databaseFactoryFfi.openDatabase(newerPath);
      await db.execute(
        'CREATE TABLE samples (id TEXT PRIMARY KEY, geohash TEXT NOT NULL)',
      );
      await db.execute(
        'PRAGMA user_version = ${DatabaseService.databaseVersion + 1}',
      );
      await db.close();

      await expectLater(
        backupService.restoreFromFile(newerPath),
        throwsA(
          isA<DatabaseBackupException>().having(
            (e) => e.error,
            'error',
            DatabaseBackupValidationError.newerVersion,
          ),
        ),
      );
      expect(await databaseService.getSampleCount(), 3);
    });

    test('restore refuses a database without the samples table', () async {
      final foreignPath = p.join(tempDir.path, 'foreign.db');
      final db = await databaseFactoryFfi.openDatabase(foreignPath);
      await db.execute('CREATE TABLE something_else (id INTEGER)');
      await db.close();

      await expectLater(
        backupService.restoreFromFile(foreignPath),
        throwsA(
          isA<DatabaseBackupException>().having(
            (e) => e.error,
            'error',
            DatabaseBackupValidationError.missingTables,
          ),
        ),
      );
      expect(await databaseService.getSampleCount(), 3);
    });

    test('restore deletes stale sidecar files of the live database', () async {
      await backupService.exportToFile(backupPath);
      final livePath = (await databaseService.database).path;
      await databaseService.close();

      for (final suffix in const ['-wal', '-shm', '-journal']) {
        await File('$livePath$suffix').writeAsString('stale $suffix');
      }

      await backupService.restoreFromFile(backupPath);

      for (final suffix in const ['-wal', '-shm', '-journal']) {
        expect(
          File('$livePath$suffix').existsSync(),
          isFalse,
          reason: 'stale sidecar $suffix must be removed',
        );
      }
      expect(await databaseService.getSampleCount(), 3);
    });

    test(
      'restore rolls back to the previous database when reopening fails',
      () async {
        // A backup that passes validation but breaks the upgrade path: it
        // claims schema version 5 while already carrying the sessions table,
        // so the version-6 migration (CREATE TABLE sessions) fails on reopen.
        final brokenPath = p.join(tempDir.path, 'broken_migration.db');
        final db = await databaseFactoryFfi.openDatabase(brokenPath);
        await db.execute('''
        CREATE TABLE samples (
          id TEXT PRIMARY KEY,
          lat REAL NOT NULL,
          lon REAL NOT NULL,
          timestamp INTEGER NOT NULL,
          path TEXT,
          geohash TEXT NOT NULL,
          rssi INTEGER,
          snr INTEGER,
          pingSuccess INTEGER,
          observerNames TEXT,
          uploaded INTEGER DEFAULT 0
        )
      ''');
        await db.execute('''
        CREATE TABLE sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          distance_meters REAL DEFAULT 0,
          sample_count INTEGER DEFAULT 0,
          ping_count INTEGER DEFAULT 0,
          success_count INTEGER DEFAULT 0,
          notes TEXT
        )
      ''');
        await db.execute('PRAGMA user_version = 5');
        await db.close();

        await expectLater(
          backupService.restoreFromFile(brokenPath),
          throwsA(anything),
        );

        // The previous database is back in place and fully usable.
        expect(await databaseService.getSampleCount(), 3);
        expect((await databaseService.getAllSessions()).single.notes, 'seed');
      },
    );
  });
}

/// Populates the database with one row per interesting shape: a plain GPS
/// sample, a fully attributed successful ping, and a failed ping.
Future<void> _seedDemoData(DatabaseService db) async {
  final base = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  await db.insertSamples([
    Sample(
      id: 's1',
      position: const LatLng(55.1, 37.1),
      timestamp: base,
      geohash: 'ucfunr',
    ),
    Sample(
      id: 's2',
      position: const LatLng(55.2, 37.2),
      timestamp: base.add(const Duration(minutes: 1)),
      geohash: 'ucfunr',
      rssi: -90,
      snr: 5,
      pingSuccess: true,
      responseTimeMs: 320,
      ductingRisk: 'possible',
      source: 'unit-a',
      deviceId: 'pk1',
    ),
    Sample(
      id: 's3',
      position: const LatLng(55.3, 37.3),
      timestamp: base.add(const Duration(minutes: 2)),
      geohash: 'ucfunr',
      pingSuccess: false,
    ),
  ]);

  await db.createSession(
    WSession(
      startTime: base,
      endTime: base.add(const Duration(hours: 1)),
      distanceMeters: 1200.5,
      sampleCount: 3,
      pingCount: 2,
      successCount: 1,
      notes: 'seed',
    ),
  );

  await db.addMarker(55.0, 37.0, 'planned repeater');
  await db.addPrivacyZone(55.5, 37.5, 250, 'home');
  await db.addImpossibleZone(56.0, 38.0, 1000, 'sea');
  await db.upsertDevice('pk1', 'unit-a', 'ble');
  await db.markSamplesAsUploadedToEndpoint(['s1'], 'https://example.org/api');
}
