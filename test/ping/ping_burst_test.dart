import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/utils/ping_burst.dart';

Sample _sample(
  String id, {
  DateTime? timestamp,
  String? path,
  int? rssi,
  bool? pingSuccess = true,
  String geohash = 'ucftpv1',
}) {
  return Sample(
    id: id,
    position: const LatLng(55.75, 37.62),
    timestamp: timestamp ?? DateTime.utc(2026, 8, 13, 12),
    path: path,
    geohash: geohash,
    rssi: rssi,
    snr: rssi == null ? null : -rssi ~/ 10,
    pingSuccess: pingSuccess,
  );
}

void main() {
  group('PingBurst.responsesFor', () {
    test('returns same-burst responses ordered strongest first', () {
      final at = DateTime.utc(2026, 8, 13, 12);
      final tapped = _sample('a', timestamp: at, path: 'AA11', rssi: -95);
      final samples = [
        _sample(
          'b',
          timestamp: at.add(const Duration(milliseconds: 40)),
          path: 'BB22',
          rssi: -80,
        ),
        tapped,
        _sample(
          'c',
          timestamp: at.add(const Duration(milliseconds: 80)),
          path: 'CC33',
          rssi: -110,
        ),
      ];

      final responses = PingBurst.responsesFor(tapped, samples);

      expect(responses.map((s) => s.id), ['b', 'a', 'c']);
    });

    test('keeps the tapped sample when it succeeded', () {
      final tapped = _sample('a', path: 'AA11', rssi: -90);

      final responses = PingBurst.responsesFor(tapped, [tapped]);

      expect(responses, hasLength(1));
      expect(responses.single.id, 'a');
    });

    test('excludes other geohashes and outside the collection window', () {
      final at = DateTime.utc(2026, 8, 13, 12);
      final tapped = _sample('a', timestamp: at, path: 'AA11', rssi: -90);
      final samples = [
        _sample(
          'far',
          timestamp: at.add(const Duration(seconds: 5)),
          path: 'FF00',
          rssi: -70,
        ),
        _sample(
          'other-cell',
          timestamp: at,
          path: 'EE11',
          rssi: -70,
          geohash: 'ucftpv9',
        ),
        _sample('weak-but-inside', timestamp: at, path: 'DD44', rssi: -118),
      ];

      final responses = PingBurst.responsesFor(tapped, samples);

      expect(responses.map((s) => s.id), ['weak-but-inside']);
    });

    test('ignores failed pings and GPS-only samples from the burst window', () {
      final at = DateTime.utc(2026, 8, 13, 12);
      final tapped = _sample('a', timestamp: at, path: 'AA11', rssi: -90);
      final samples = [
        _sample('failed', timestamp: at, path: null, pingSuccess: false),
        _sample('gps-only', timestamp: at, path: null, pingSuccess: null),
        tapped,
      ];

      expect(PingBurst.responsesFor(tapped, samples), hasLength(1));
    });
  });

  group('PingBurst.bestRssi', () {
    test('picks the highest reported RSSI', () {
      final samples = [
        _sample('a', rssi: -105),
        _sample('b', rssi: -72),
        _sample('c', rssi: -90),
      ];

      expect(PingBurst.bestRssi(samples), -72);
    });

    test('returns null when no sample carries a signal level', () {
      expect(PingBurst.bestRssi([_sample('a'), _sample('b')]), isNull);
      expect(PingBurst.bestRssi(const <Sample>[]), isNull);
    });
  });
}
