import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';

import '../helpers/database_harness.dart';
import '../helpers/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useSqfliteFfi();

  final harness = DatabaseHarness();
  final base = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  setUp(harness.setUp);
  tearDown(harness.tearDown);

  List<Sample> seedSamples() => [
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
      path: 'rp1',
      rssi: -90,
      snr: 5,
      pingSuccess: true,
      responseTimeMs: 320,
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
  ];

  group('exportAllData', () {
    test('embeds samples and sessions in the unified format', () async {
      final db = harness.databaseService;
      await db.insertSamples(seedSamples());
      await db.createSession(
        WSession(
          startTime: base,
          endTime: base.add(const Duration(hours: 1)),
          sampleCount: 3,
          notes: 'session notes',
        ),
      );

      final data = await db.exportAllData();
      expect(data['_format'], 'meshcore_wardrive_data');
      expect(data['_version'], 2);

      final samples = data['samples'] as List<dynamic>;
      expect(samples, hasLength(3));
      expect(
        (samples.first as Map<String, dynamic>)['id'],
        anyOf('s1', 's2', 's3'),
      );

      final sessions = data['sessions'] as List<dynamic>;
      expect(
        (sessions.single as Map<String, dynamic>)['notes'],
        'session notes',
      );
    });

    test('omits the repeaters key when none are provided', () async {
      final db = harness.databaseService;
      final without = await db.exportAllData();
      expect(without.containsKey('repeaters'), isFalse);

      final withEmpty = await db.exportAllData(repeaters: []);
      expect(withEmpty.containsKey('repeaters'), isFalse);

      final repeater = Repeater(
        id: 'rp1',
        position: const LatLng(56.0, 38.0),
        name: 'Hill',
      );
      final withRepeaters = await db.exportAllData(
        repeaters: [repeater.toJson()],
      );
      expect((withRepeaters['repeaters'] as List<dynamic>), hasLength(1));
    });

    test(
      'excludes samples inside privacy zones from the shared JSON',
      () async {
        final db = harness.databaseService;
        await db.insertSamples([
          Sample(
            id: 'home',
            position: const LatLng(55.0, 37.0),
            timestamp: base,
            geohash: 'ucfunr',
          ),
          Sample(
            id: 'away',
            position: const LatLng(55.5, 37.5),
            timestamp: base,
            geohash: 'ucfunr',
          ),
        ]);
        await db.addPrivacyZone(55.0, 37.0, 250, 'home');

        final data = await db.exportAllData();
        final ids = (data['samples'] as List<dynamic>).map(
          (s) => (s as Map<String, dynamic>)['id'],
        );
        expect(ids, ['away']);
      },
    );
  });

  group('importAllData unified format', () {
    test('export → wipe → import restores samples and sessions', () async {
      final db = harness.databaseService;
      await db.insertSamples(seedSamples());
      await db.createSession(
        WSession(
          startTime: base,
          endTime: base.add(const Duration(hours: 1)),
          sampleCount: 3,
          pingCount: 2,
          successCount: 1,
          notes: 'seed',
        ),
      );
      final exported = await db.exportAllData();

      // Wipe everything the export contains.
      await db.deleteAllSamples();
      for (final session in await db.getAllSessions()) {
        await db.deleteSession(session.id!);
      }

      final counts = await db.importAllData(exported);
      expect(counts['samples'], 3);
      expect(counts['sessions'], 1);

      final samples = await db.getAllSamples();
      expect(samples.map((s) => s.id), unorderedEquals(['s1', 's2', 's3']));
      final s2 = samples.singleWhere((s) => s.id == 's2');
      expect(s2.rssi, -90);
      expect(s2.pingSuccess, isTrue);
      expect(s2.path, 'rp1');
      expect(s2.source, 'unit-a');

      final session = (await db.getAllSessions()).single;
      expect(session.notes, 'seed');
      expect(session.sampleCount, 3);
      expect(session.startTime, base);
    });

    test('re-importing the same export imports nothing new', () async {
      final db = harness.databaseService;
      await db.insertSamples(seedSamples());
      await db.createSession(WSession(startTime: base, notes: 'seed'));
      final exported = await db.exportAllData();

      final first = await db.importAllData(exported);
      expect(first['samples'], 0, reason: 'ids already exist');
      expect(first['sessions'], 0, reason: 'start_time already exists');
      expect(await db.getSampleCount(), 3);
      expect(await db.getAllSessions(), hasLength(1));
    });

    test('deduplicates sessions by start_time across imports', () async {
      final db = harness.databaseService;
      final sessionJson = WSession(startTime: base, notes: 'v1').toJson();

      final first = await db.importAllData({
        'samples': <Map<String, dynamic>>[],
        'sessions': [sessionJson],
      });
      expect(first['sessions'], 1);

      final second = await db.importAllData({
        'samples': <Map<String, dynamic>>[],
        'sessions': [
          WSession(
            startTime: base,
            notes: 'different notes, same start',
          ).toJson(),
        ],
      });
      expect(second['sessions'], 0);

      final sessions = await db.getAllSessions();
      expect(sessions, hasLength(1));
      expect(sessions.single.notes, 'v1');
    });

    test('skips malformed rows and imports the rest', () async {
      final db = harness.databaseService;
      final valid = seedSamples().first.toJson();

      final counts = await db.importAllData({
        'samples': [
          valid,
          // Missing geohash: Sample.fromJson cannot build the row.
          {
            'id': 'no-geohash',
            'lat': 1.0,
            'lon': 2.0,
            'timestamp': base.toIso8601String(),
          },
          // Non-numeric latitude.
          {
            'id': 'bad-lat',
            'lat': 'north',
            'lon': 2.0,
            'timestamp': base.toIso8601String(),
            'geohash': 'ucfunr',
          },
          // Session rows without startTime are dropped, valid ones kept.
        ],
        'sessions': [
          WSession(startTime: base, notes: 'good').toJson(),
          {'notes': 'no start time'},
        ],
      });

      expect(counts['samples'], 1);
      expect(counts['sessions'], 1);
      expect((await db.getAllSamples()).single.id, 's1');
      expect((await db.getAllSessions()).single.notes, 'good');
    });

    test('rejects an unrecognized payload with FormatException', () async {
      final db = harness.databaseService;

      await expectLater(
        db.importAllData({'unexpected': 'shape'}),
        throwsFormatException,
      );
      await expectLater(
        db.importAllData('just a string'),
        throwsFormatException,
      );
      expect(await db.getSampleCount(), 0);
    });
  });

  group('importAllData legacy format', () {
    test('imports a plain array of samples', () async {
      final db = harness.databaseService;
      final counts = await db.importAllData(
        seedSamples().map((s) => s.toJson()).toList(),
      );

      expect(counts['samples'], 3);
      expect(counts['sessions'], 0);
      expect(await db.getSampleCount(), 3);
    });

    test('re-importing a legacy array imports nothing new', () async {
      final db = harness.databaseService;
      final legacy = seedSamples().map((s) => s.toJson()).toList();

      expect((await db.importAllData(legacy))['samples'], 3);
      expect((await db.importAllData(legacy))['samples'], 0);
      expect(await db.getSampleCount(), 3);
    });
  });

  group('importSamples', () {
    test('returns the row delta and ignores duplicate ids', () async {
      final db = harness.databaseService;
      final rows = seedSamples().map((s) => s.toJson()).toList();

      expect(await db.importSamples(rows), 3);
      expect(await db.importSamples(rows), 0);
      expect(await db.getSampleCount(), 3);
    });

    test(
      'skips rows that fail validation without aborting the batch',
      () async {
        final db = harness.databaseService;
        final good = seedSamples().first.toJson();

        final imported = await db.importSamples([
          good,
          {'no': 'required fields'},
        ]);
        expect(imported, 1);
        expect((await db.getAllSamples()).single.id, 's1');
      },
    );
  });
}
