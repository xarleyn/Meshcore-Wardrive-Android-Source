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

  Sample sample({
    String id = 's1',
    double lat = 55.0,
    double lon = 37.0,
    DateTime? at,
    String geohash = 'ucfunr',
    String? path,
    int? rssi,
    int? snr,
    bool? pingSuccess,
    int? responseTimeMs,
    String? source,
    String? deviceId,
  }) {
    return Sample(
      id: id,
      position: LatLng(lat, lon),
      timestamp: at ?? base,
      geohash: geohash,
      path: path,
      rssi: rssi,
      snr: snr,
      pingSuccess: pingSuccess,
      responseTimeMs: responseTimeMs,
      source: source,
      deviceId: deviceId,
    );
  }

  setUp(harness.setUp);
  tearDown(harness.tearDown);

  group('sample CRUD', () {
    test('insert, duplicate id is ignored, newest first ordering', () async {
      final db = harness.databaseService;
      await db.insertSample(sample(id: 'a', at: base, lat: 1.0));
      await db.insertSample(sample(id: 'a', at: base, lat: 99.0));
      await db.insertSample(
        sample(id: 'b', at: base.add(const Duration(minutes: 1)), lat: 2.0),
      );

      expect(await db.getSampleCount(), 2);
      final all = await db.getAllSamples();
      expect(all.map((s) => s.id).toList(), ['b', 'a']);
      expect(all.singleWhere((s) => s.id == 'a').position.latitude, 1.0);

      final mostRecent = await db.getMostRecentSample();
      expect(mostRecent?.id, 'b');
    });

    test('path and ping attributes survive the round trip', () async {
      final db = harness.databaseService;
      await db.insertSample(
        sample(
          id: 'p1',
          path: 'repeater-1',
          rssi: -87,
          snr: 6,
          pingSuccess: true,
          responseTimeMs: 250,
          source: 'unit-a',
          deviceId: 'pk1',
        ),
      );

      final loaded = (await db.getMostRecentSample())!;
      expect(loaded.path, 'repeater-1');
      expect(loaded.rssi, -87);
      expect(loaded.pingSuccess, isTrue);
      expect(loaded.responseTimeMs, 250);
      expect(loaded.source, 'unit-a');
      expect(loaded.deviceId, 'pk1');
    });

    test(
      'insertSamples stores a batch and deleteAllSamples clears it',
      () async {
        final db = harness.databaseService;
        await db.insertSamples([
          sample(id: 'a', at: base),
          sample(id: 'b', at: base),
          sample(id: 'c', at: base),
        ]);
        expect(await db.getSampleCount(), 3);

        await db.deleteAllSamples();
        expect(await db.getSampleCount(), 0);
        expect(await db.getMostRecentSample(), isNull);
      },
    );

    test(
      'deleteSample and deleteSamplesByGeohash remove only matches',
      () async {
        final db = harness.databaseService;
        await db.insertSamples([
          sample(id: 'a', geohash: 'ucfxaaa1'),
          sample(id: 'b', geohash: 'ucfxaaa2'),
          sample(id: 'c', geohash: 'other999'),
        ]);

        await db.deleteSample('a');
        expect((await db.getAllSamples()).map((s) => s.id), ['c', 'b']);

        final deleted = await db.deleteSamplesByGeohash('ucfxaaa');
        expect(deleted, 1);
        expect((await db.getAllSamples()).single.id, 'c');
      },
    );
  });

  group('time range queries', () {
    test('getSamplesByTimeRange is inclusive on both ends', () async {
      final db = harness.databaseService;
      final t1 = base;
      final t2 = base.add(const Duration(minutes: 1));
      final t3 = base.add(const Duration(minutes: 2));
      await db.insertSamples([
        sample(id: 'a', at: t1),
        sample(id: 'b', at: t2),
        sample(id: 'c', at: t3),
      ]);

      final range = await db.getSamplesByTimeRange(t1, t3);
      expect(range.map((s) => s.id), unorderedEquals(['a', 'b', 'c']));

      final narrow = await db.getSamplesByTimeRange(
        base.add(const Duration(seconds: 30)),
        base.add(const Duration(minutes: 1, seconds: 30)),
      );
      expect(narrow.map((s) => s.id), ['b']);
    });

    test(
      'getSamplesSince and deleteSamplesOlderThan split the history',
      () async {
        final db = harness.databaseService;
        await db.insertSamples([
          sample(id: 'old', at: base),
          sample(id: 'new', at: base.add(const Duration(hours: 1))),
        ]);

        final cutoff = base.add(const Duration(minutes: 30));
        expect((await db.getSamplesSince(cutoff)).map((s) => s.id), ['new']);

        await db.deleteSamplesOlderThan(cutoff);
        expect((await db.getAllSamples()).single.id, 'new');
      },
    );
  });

  group('legacy upload tracking', () {
    test(
      'markSamplesAsUploaded moves samples out of the pending list',
      () async {
        final db = harness.databaseService;
        await db.insertSamples([sample(id: 'a'), sample(id: 'b')]);

        expect(await db.getUnuploadedSampleCount(), 2);
        expect(
          (await db.getUnuploadedSamples()).map((s) => s.id),
          unorderedEquals(['a', 'b']),
        );

        await db.markSamplesAsUploaded(['a']);
        expect(await db.getUnuploadedSampleCount(), 1);
        expect((await db.getUnuploadedSamples()).single.id, 'b');
      },
    );
  });

  group('per-endpoint upload tracking', () {
    test('pending samples are tracked per endpoint', () async {
      final db = harness.databaseService;
      await db.insertSamples([sample(id: 'a'), sample(id: 'b')]);
      const endpointA = 'https://a.example.org/api';
      const endpointB = 'https://b.example.org/api';

      await db.markSamplesAsUploadedToEndpoint(['a'], endpointA);

      expect(
        (await db.getUnuploadedSamplesForEndpoint(endpointA)).map((s) => s.id),
        ['b'],
        reason: 'a is uploaded to A, b is not',
      );
      expect(
        (await db.getUnuploadedSamplesForEndpoint(endpointB)).map((s) => s.id),
        unorderedEquals(['a', 'b']),
        reason: 'uploading to A does not affect B',
      );

      await db.markSamplesAsUploadedToEndpoint(['a'], endpointB);
      expect(
        (await db.getUnuploadedSamplesForEndpoint(endpointB)).map((s) => s.id),
        ['b'],
        reason: 'only b has never been uploaded to B',
      );
    });

    test(
      're-uploading to the same endpoint does not duplicate the row',
      () async {
        final db = harness.databaseService;
        await db.insertSample(sample(id: 'a'));
        const endpoint = 'https://a.example.org/api';

        await db.markSamplesAsUploadedToEndpoint(['a'], endpoint);
        await db.markSamplesAsUploadedToEndpoint(['a'], endpoint);

        final uploads = await (await db.database).query('uploads');
        expect(uploads, hasLength(1));
        expect(await db.getUnuploadedSamplesForEndpoint(endpoint), isEmpty);
      },
    );
  });

  group('sessions', () {
    test('create, read newest first, update, delete', () async {
      final db = harness.databaseService;
      final first = WSession(
        startTime: base,
        endTime: base.add(const Duration(hours: 1)),
        distanceMeters: 1000,
        sampleCount: 10,
        pingCount: 4,
        successCount: 2,
        notes: 'first',
      );
      final second = WSession(startTime: base.add(const Duration(days: 1)));

      final firstId = await db.createSession(first);
      await db.createSession(second);

      final sessions = await db.getAllSessions();
      expect(sessions, hasLength(2));
      expect(sessions.first.startTime, second.startTime);
      final loaded = sessions.last;
      expect(loaded.id, firstId);
      expect(loaded.duration, const Duration(hours: 1));
      expect(loaded.successRate, 0.5);

      final updated = WSession(
        id: firstId,
        startTime: first.startTime,
        endTime: first.endTime,
        distanceMeters: 2000,
        sampleCount: 12,
        pingCount: 5,
        successCount: 3,
        notes: 'updated',
      );
      await db.updateSession(updated);
      final afterUpdate = (await db.getAllSessions()).singleWhere(
        (s) => s.id == firstId,
      );
      expect(afterUpdate.distanceMeters, 2000);
      expect(afterUpdate.notes, 'updated');
      expect(afterUpdate.successRate, closeTo(0.6, 0.0001));

      await db.deleteSession(firstId);
      expect((await db.getAllSessions()).single.id, isNot(firstId));
    });

    test(
      'getSessionSampleCounts aggregates ping outcomes in a window',
      () async {
        final db = harness.databaseService;
        await db.insertSamples([
          sample(id: 'plain', at: base),
          sample(id: 'failed', at: base, pingSuccess: false),
          sample(id: 'success', at: base, pingSuccess: true),
          sample(
            id: 'outside',
            at: base.add(const Duration(days: 1)),
            pingSuccess: true,
          ),
        ]);

        final counts = await db.getSessionSampleCounts(
          base.subtract(const Duration(minutes: 1)),
          base.add(const Duration(minutes: 1)),
        );
        expect(counts['total'], 3);
        expect(counts['pings'], 2);
        expect(counts['successes'], 1);
      },
    );

    test('getSessionSampleCounts returns zeros for an empty window', () async {
      final db = harness.databaseService;
      final counts = await db.getSessionSampleCounts(base, base);
      expect(counts, {'total': 0, 'pings': 0, 'successes': 0});
    });
  });

  group('sources and repeater paths', () {
    test('getDistinctSources is sorted and skips null', () async {
      final db = harness.databaseService;
      await db.insertSamples([
        sample(id: 'a', source: 'unit-b'),
        sample(id: 'b', source: 'unit-a'),
        sample(id: 'c'),
      ]);

      expect(await db.getDistinctSources(), ['unit-a', 'unit-b']);
      expect((await db.getSamplesBySource('unit-a')).map((s) => s.id), ['b']);
    });

    test('getDistinctRepeaterIds uppercases and skips empty paths', () async {
      final db = harness.databaseService;
      await db.insertSamples([
        sample(id: 'a', path: 'rp1'),
        sample(id: 'b', path: 'rp1'),
        sample(id: 'c', path: 'rp2'),
        sample(id: 'd', path: ''),
        sample(id: 'e'),
      ]);

      expect(await db.getDistinctRepeaterIds(), {'RP1', 'RP2'});
    });
  });

  group('dead zone detection', () {
    test('cell is dead only when it has pings and none succeeded', () async {
      final db = harness.databaseService;
      await db.insertSamples([
        sample(id: 'f1', geohash: 'failed01', pingSuccess: false),
        sample(id: 'f2', geohash: 'failed01', pingSuccess: false),
        sample(id: 'm1', geohash: 'mixed001', pingSuccess: false),
        sample(id: 'm2', geohash: 'mixed001', pingSuccess: true),
        sample(id: 'n1', geohash: 'noping01'),
      ]);

      expect(await db.isDeadZoneCell('failed01'), isTrue);
      expect(await db.isDeadZoneCell('mixed001'), isFalse);
      expect(
        await db.isDeadZoneCell('noping01'),
        isFalse,
        reason: 'samples without ping data are not dead-zone evidence',
      );
      expect(
        await db.isDeadZoneCell('empty000'),
        isFalse,
        reason: 'no samples at all is not a dead zone',
      );
    });
  });

  group('privacy zones', () {
    test('zones persisted in the database filter samples out', () async {
      final db = harness.databaseService;
      final inside = sample(id: 'inside', lat: 55.0, lon: 37.0);
      final outside = sample(id: 'outside', lat: 55.1, lon: 37.0);

      expect(
        await db.filterByPrivacyZones([inside, outside]),
        unorderedEquals([inside, outside]),
        reason: 'no zones configured yet',
      );

      await db.addPrivacyZone(55.0, 37.0, 250, 'home');
      final filtered = await db.filterByPrivacyZones([inside, outside]);
      expect(filtered.single.id, 'outside');
    });

    test('deletePrivacyZone removes the zone and stops filtering', () async {
      final db = harness.databaseService;
      final id = await db.addPrivacyZone(55.0, 37.0, 250, 'home');
      expect((await db.getAllPrivacyZones()).single['label'], 'home');

      await db.deletePrivacyZone(id);
      expect(await db.getAllPrivacyZones(), isEmpty);

      final inside = sample(id: 'inside', lat: 55.0, lon: 37.0);
      expect(await db.filterByPrivacyZones([inside]), [inside]);
    });
  });

  group('impossible zones', () {
    test('findImpossibleZoneAt locates the containing zone', () async {
      final db = harness.databaseService;
      expect(await db.findImpossibleZoneAt(56.0, 38.0), isNull);

      await db.addImpossibleZone(56.0, 38.0, 1000, 'sea');
      final zone = await db.findImpossibleZoneAt(56.0, 38.0);
      expect(zone, isNotNull);
      expect(zone!.label, 'sea');
      expect(await db.findImpossibleZoneAt(56.1, 38.0), isNull);

      await db.deleteImpossibleZone(zone.id!);
      expect(await db.getAllImpossibleZones(), isEmpty);
    });
  });

  group('devices', () {
    test('upsertDevice inserts then updates keeping first_used', () async {
      final db = harness.databaseService;
      await db.upsertDevice('pk1', 'unit-a', 'ble');
      final created = (await db.getAllDevices()).single;
      expect(created['name'], 'unit-a');
      expect(created['first_used'], created['last_used']);

      await db.upsertDevice('pk1', 'renamed', 'usb');
      final updated = (await db.getAllDevices()).single;
      expect(updated['name'], 'renamed');
      expect(updated['connection_type'], 'usb');
      expect(updated['first_used'], created['first_used']);
      expect(updated['last_used'], greaterThanOrEqualTo(created['last_used']));
    });

    test('getAllDevices orders by last_used descending', () async {
      final db = harness.databaseService;
      await db.upsertDevice('pk-old', 'older', 'ble');
      // last_used is ms-resolution; a busy second could tie the two rows.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await db.upsertDevice('pk-new', 'newer', 'usb');

      final devices = await db.getAllDevices();
      expect(devices.map((d) => d['public_key']).toList(), [
        'pk-new',
        'pk-old',
      ]);
    });

    test(
      'getDeviceStats aggregates only ping-bearing samples of the device',
      () async {
        final db = harness.databaseService;
        await db.insertSamples([
          sample(
            id: 'ok1',
            geohash: 'aaaaa1',
            pingSuccess: true,
            snr: 10,
            rssi: -80,
            responseTimeMs: 100,
            deviceId: 'pk1',
          ),
          sample(
            id: 'ok2',
            geohash: 'aaaaa2',
            pingSuccess: true,
            snr: 20,
            rssi: -90,
            responseTimeMs: 200,
            deviceId: 'pk1',
          ),
          sample(
            id: 'fail',
            geohash: 'aaaaa3',
            pingSuccess: false,
            snr: 99,
            rssi: -10,
            responseTimeMs: 999,
            deviceId: 'pk1',
          ),
          sample(
            id: 'other-device',
            geohash: 'aaaaa4',
            pingSuccess: true,
            snr: 50,
            deviceId: 'pk2',
          ),
          sample(id: 'no-device', geohash: 'aaaaa5', pingSuccess: true),
        ]);

        final stats = await db.getDeviceStats('pk1');
        expect(stats['totalPings'], 3);
        expect(stats['successes'], 2);
        expect(stats['failures'], 1);
        expect(stats['successRate'], closeTo(2 / 3, 0.0001));
        expect(stats['uniqueCells'], 3);
        // snr/rssi averages cover successful pings only; response time is
        // averaged over every ping-bearing sample.
        expect(stats['avgSnr'], closeTo(15.0, 0.0001));
        expect(stats['avgRssi'], closeTo(-85.0, 0.0001));
        expect(stats['avgResponseMs'], closeTo((100 + 200 + 999) / 3, 0.0001));
      },
    );

    test('getDeviceStats returns zeros for an unknown device', () async {
      final db = harness.databaseService;
      final stats = await db.getDeviceStats('missing');
      expect(stats['totalPings'], 0);
      expect(stats['successes'], 0);
      expect(stats['failures'], 0);
      expect(stats['successRate'], 0.0);
      expect(stats['uniqueCells'], 0);
      expect(stats['avgSnr'], isNull);
      expect(stats['avgRssi'], isNull);
      expect(stats['avgResponseMs'], isNull);
    });
  });
}
