import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';

void main() {
  final base = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  group('Sample JSON serialization', () {
    test('toJson → fromJson preserves every field', () {
      final sample = Sample(
        id: 's1',
        position: const LatLng(55.123456, 37.654321),
        timestamp: base,
        path: 'repeater-1',
        geohash: 'ucfunr',
        rssi: -90,
        snr: 5,
        pingSuccess: true,
        responseTimeMs: 320,
        ductingRisk: 'possible',
        source: 'unit-a',
        deviceId: 'pk1',
      );

      final restored = Sample.fromJson(sample.toJson());

      expect(restored.id, sample.id);
      expect(restored.position.latitude, sample.position.latitude);
      expect(restored.position.longitude, sample.position.longitude);
      expect(restored.timestamp, sample.timestamp);
      expect(restored.path, sample.path);
      expect(restored.geohash, sample.geohash);
      expect(restored.rssi, sample.rssi);
      expect(restored.snr, sample.snr);
      expect(restored.pingSuccess, sample.pingSuccess);
      expect(restored.responseTimeMs, sample.responseTimeMs);
      expect(restored.ductingRisk, sample.ductingRisk);
      expect(restored.source, sample.source);
      expect(restored.deviceId, sample.deviceId);
    });

    test('toJson → fromJson keeps optional fields null', () {
      final sample = Sample(
        id: 's2',
        position: const LatLng(1.0, 2.0),
        timestamp: base,
        geohash: 'aaaaaa',
      );

      final restored = Sample.fromJson(sample.toJson());

      expect(restored.path, isNull);
      expect(restored.rssi, isNull);
      expect(restored.snr, isNull);
      expect(restored.pingSuccess, isNull);
      expect(restored.responseTimeMs, isNull);
      expect(restored.ductingRisk, isNull);
      expect(restored.source, isNull);
      expect(restored.deviceId, isNull);
    });

    test('fromJson accepts integer coordinates', () {
      final restored = Sample.fromJson({
        'id': 's3',
        'lat': 55,
        'lon': 37,
        'timestamp': base.toIso8601String(),
        'geohash': 'ucfunr',
      });

      expect(restored.position.latitude, 55.0);
      expect(restored.position.longitude, 37.0);
    });
  });

  group('Sample SQLite serialization', () {
    test('toMap → fromMap preserves every field', () {
      final sample = Sample(
        id: 's1',
        position: const LatLng(55.123456, 37.654321),
        timestamp: base,
        path: 'repeater-1',
        geohash: 'ucfunr',
        rssi: -90,
        snr: 5,
        pingSuccess: true,
        responseTimeMs: 320,
        ductingRisk: 'possible',
        source: 'unit-a',
        deviceId: 'pk1',
      );

      final restored = Sample.fromMap(sample.toMap());

      expect(restored.id, sample.id);
      expect(restored.position.latitude, sample.position.latitude);
      expect(restored.position.longitude, sample.position.longitude);
      expect(restored.timestamp, sample.timestamp);
      expect(restored.path, sample.path);
      expect(restored.rssi, sample.rssi);
      expect(restored.snr, sample.snr);
      expect(restored.pingSuccess, sample.pingSuccess);
      expect(restored.responseTimeMs, sample.responseTimeMs);
      expect(restored.ductingRisk, sample.ductingRisk);
      expect(restored.source, sample.source);
      expect(restored.deviceId, sample.deviceId);
    });

    test('pingSuccess maps to the 0/1/null column convention', () {
      expect(
        Sample(
          id: 's',
          position: const LatLng(1, 2),
          timestamp: base,
          geohash: 'g',
          pingSuccess: true,
        ).toMap()['pingSuccess'],
        1,
      );
      expect(
        Sample(
          id: 's',
          position: const LatLng(1, 2),
          timestamp: base,
          geohash: 'g',
          pingSuccess: false,
        ).toMap()['pingSuccess'],
        0,
      );
      expect(
        Sample(
          id: 's',
          position: const LatLng(1, 2),
          timestamp: base,
          geohash: 'g',
        ).toMap()['pingSuccess'],
        isNull,
      );
    });
  });

  group('WSession serialization', () {
    test('toJson → fromJson preserves every field', () {
      final session = WSession(
        startTime: base,
        endTime: base.add(const Duration(hours: 1)),
        distanceMeters: 1500.5,
        sampleCount: 42,
        pingCount: 10,
        successCount: 7,
        notes: 'evening run',
      );

      final restored = WSession.fromJson(session.toJson());

      expect(restored.startTime, session.startTime);
      expect(restored.endTime, session.endTime);
      expect(restored.distanceMeters, session.distanceMeters);
      expect(restored.sampleCount, session.sampleCount);
      expect(restored.pingCount, session.pingCount);
      expect(restored.successCount, session.successCount);
      expect(restored.notes, session.notes);
    });

    test('toMap → fromMap preserves the id and null end time', () {
      final session = WSession(id: 7, startTime: base);

      final restored = WSession.fromMap(session.toMap());
      expect(restored.id, 7);
      expect(restored.endTime, isNull);
      expect(restored.duration, isNull);

      // A session without an id must not put a null id into the map,
      // so SQLite assigns the autoincrement key on insert.
      expect(WSession(startTime: base).toMap().containsKey('id'), isFalse);
    });

    test('successRate is zero without pings', () {
      expect(WSession(startTime: base).successRate, 0.0);
      expect(
        WSession(startTime: base, pingCount: 4, successCount: 1).successRate,
        0.25,
      );
    });
  });

  group('Coverage JSON serialization', () {
    test('toJson → fromJson preserves every field', () {
      final coverage = Coverage(
        id: 'ucfunr',
        position: const LatLng(55.1, 37.2),
        received: 12.0,
        lost: 3.0,
        lastReceived: base,
        updated: base.add(const Duration(minutes: 1)),
        repeaters: ['rp1', 'rp2'],
      );

      final restored = Coverage.fromJson(coverage.toJson());

      expect(restored.id, coverage.id);
      expect(restored.position.latitude, coverage.position.latitude);
      expect(restored.position.longitude, coverage.position.longitude);
      expect(restored.received, coverage.received);
      expect(restored.lost, coverage.lost);
      expect(restored.lastReceived, coverage.lastReceived);
      expect(restored.updated, coverage.updated);
      expect(restored.repeaters, coverage.repeaters);
    });

    test('fromJson fills defaults for missing optional fields', () {
      final restored = Coverage.fromJson({
        'id': 'ucfunr',
        'lat': 55.1,
        'lon': 37.2,
      });

      expect(restored.received, 0.0);
      expect(restored.lost, 0.0);
      expect(restored.lastReceived, isNull);
      expect(restored.updated, isNull);
      expect(restored.repeaters, isEmpty);
    });
  });

  group('Repeater JSON serialization', () {
    test('toJson → fromJson preserves every field', () {
      final repeater = Repeater(
        id: 'rp1',
        position: const LatLng(56.0, 38.0),
        elevation: 210.5,
        timestamp: base,
        name: 'Hill',
        rssi: -85,
        snr: 6,
        distance: 1234.5,
      );

      final restored = Repeater.fromJson(repeater.toJson());

      expect(restored.id, repeater.id);
      expect(restored.position.latitude, repeater.position.latitude);
      expect(restored.position.longitude, repeater.position.longitude);
      expect(restored.elevation, repeater.elevation);
      expect(restored.timestamp, repeater.timestamp);
      expect(restored.name, repeater.name);
      expect(restored.rssi, repeater.rssi);
      expect(restored.snr, repeater.snr);
      expect(restored.distance, repeater.distance);
    });

    test('fromJson keeps optional fields null', () {
      final restored = Repeater.fromJson({
        'id': 'rp1',
        'lat': 56.0,
        'lon': 38.0,
      });

      expect(restored.elevation, isNull);
      expect(restored.timestamp, isNull);
      expect(restored.name, isNull);
      expect(restored.rssi, isNull);
      expect(restored.snr, isNull);
      expect(restored.distance, isNull);
    });
  });

  group('NodeData deserialization', () {
    test('fromJson parses nested samples and repeaters', () {
      final data = NodeData.fromJson({
        'samples': [
          {
            'id': 's1',
            'lat': 55.0,
            'lon': 37.0,
            'timestamp': base.toIso8601String(),
            'geohash': 'ucfunr',
          },
        ],
        'repeaters': [
          {'id': 'rp1', 'lat': 56.0, 'lon': 38.0},
        ],
      });

      expect(data.samples.single.id, 's1');
      expect(data.repeaters.single.id, 'rp1');
    });

    test('fromJson tolerates missing lists', () {
      final data = NodeData.fromJson(<String, dynamic>{});

      expect(data.samples, isEmpty);
      expect(data.repeaters, isEmpty);
    });
  });
}
