import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/database_harness.dart';
import '../helpers/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useSqfliteFfi();

  final harness = DatabaseHarness();
  const defaultEndpoint = 'https://meshwar-map.pages.dev/api/samples';

  setUp(harness.setUp);
  tearDown(harness.tearDown);

  /// Creates the database file at the standard app path with the schema and
  /// user_version of an old release, so the next DatabaseService open has to
  /// run the upgrade path.
  Future<void> createLegacyDatabase(
    int version,
    Future<void> Function(Database db) build,
  ) async {
    final db = await databaseFactoryFfi.openDatabase(
      p.join(harness.tempDir.path, 'meshcore_wardrive.db'),
    );
    await build(db);
    await db.execute('PRAGMA user_version = $version');
    await db.close();
  }

  Future<Set<String>> tableNames(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    return rows.map((row) => row['name'] as String).toSet();
  }

  test('a fresh database contains every expected table', () async {
    final db = await harness.databaseService.database;

    expect(
      await tableNames(db),
      containsAll([
        DatabaseService.tableSamples,
        DatabaseService.tableDevices,
        DatabaseService.tableDuctingCache,
        DatabaseService.tableUploads,
        DatabaseService.tableSessions,
        DatabaseService.tableMarkers,
        DatabaseService.tablePrivacyZones,
        DatabaseService.tableImpossibleZones,
      ]),
    );
  });

  test('v1 database upgrades in place and keeps its samples', () async {
    await createLegacyDatabase(1, (db) async {
      // Schema as it looked before the ping columns were introduced.
      await db.execute('''
        CREATE TABLE samples (
          id TEXT PRIMARY KEY,
          lat REAL NOT NULL,
          lon REAL NOT NULL,
          timestamp INTEGER NOT NULL,
          path TEXT,
          geohash TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX idx_samples_geohash ON samples (geohash)');
      await db.execute(
        'CREATE INDEX idx_samples_timestamp ON samples (timestamp)',
      );
      await db.execute(
        "INSERT INTO samples (id, lat, lon, timestamp, path, geohash) "
        "VALUES ('old1', 55.5, 37.5, 1600000000000, 'rp-old', 'ucfxzz')",
      );
    });

    // Opening through the service runs every migration from v1 to v13.
    final db = await harness.databaseService.database;

    final legacyRows = await db.query('samples');
    expect(legacyRows, hasLength(1));
    expect(legacyRows.single['id'], 'old1');
    expect(legacyRows.single['lat'], 55.5);
    expect(legacyRows.single['lon'], 37.5);
    expect(legacyRows.single['path'], 'rp-old');

    // The added columns exist and accept fully attributed samples.
    await harness.databaseService.insertSample(
      Sample(
        id: 'new1',
        position: const LatLng(56.0, 38.0),
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        geohash: 'ucfunr',
        rssi: -80,
        snr: 4,
        pingSuccess: true,
        responseTimeMs: 120,
        ductingRisk: 'none',
        source: 'unit-a',
        deviceId: 'pk1',
      ),
    );
    final loaded = await harness.databaseService.getMostRecentSample();
    expect(loaded!.id, 'new1');
    expect(loaded.rssi, -80);
    expect(loaded.snr, 4);
    expect(loaded.pingSuccess, isTrue);
    expect(loaded.responseTimeMs, 120);
    expect(loaded.ductingRisk, 'none');
    expect(loaded.source, 'unit-a');
    expect(loaded.deviceId, 'pk1');

    // Every table introduced after v1 is present and usable.
    expect(
      await tableNames(db),
      containsAll([
        DatabaseService.tableDuctingCache,
        DatabaseService.tableUploads,
        DatabaseService.tableSessions,
        DatabaseService.tableMarkers,
        DatabaseService.tablePrivacyZones,
        DatabaseService.tableImpossibleZones,
        DatabaseService.tableDevices,
      ]),
    );
    await harness.databaseService.createSession(
      WSession(startTime: DateTime.fromMillisecondsSinceEpoch(0)),
    );
    await harness.databaseService.addMarker(1.0, 2.0, 'm');
    await harness.databaseService.addPrivacyZone(1.0, 2.0, 100, 'z');
    await harness.databaseService.addImpossibleZone(1.0, 2.0, 100, 'i');
    await harness.databaseService.upsertDevice('pk1', 'unit-a', 'ble');
    expect(await harness.databaseService.getAllSessions(), hasLength(1));
    expect(await harness.databaseService.getAllMarkers(), hasLength(1));
    expect(await harness.databaseService.getAllPrivacyZones(), hasLength(1));
    expect(await harness.databaseService.getAllImpossibleZones(), hasLength(1));
    expect(await harness.databaseService.getAllDevices(), hasLength(1));
  });

  test('v4 database migrates uploaded flags into the uploads table', () async {
    await createLegacyDatabase(4, (db) async {
      // Schema as of v4: the uploaded flag exists, the per-endpoint uploads
      // table does not yet.
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
      await db.execute(
        "INSERT INTO samples (id, lat, lon, timestamp, geohash, uploaded) "
        "VALUES ('up1', 1.0, 2.0, 1600000000000, 'aaaaaa', 1)",
      );
      await db.execute(
        "INSERT INTO samples (id, lat, lon, timestamp, geohash, uploaded) "
        "VALUES ('up2', 3.0, 4.0, 1600000000000, 'aaaaab', 0)",
      );
    });

    final db = await harness.databaseService.database;

    final uploads = await db.query(DatabaseService.tableUploads);
    expect(uploads, hasLength(1));
    expect(uploads.single['sample_id'], 'up1');
    expect(uploads.single['endpoint_url'], defaultEndpoint);

    final pending = await harness.databaseService
        .getUnuploadedSamplesForEndpoint(defaultEndpoint);
    expect(pending.map((s) => s.id), ['up2']);
  });
}
