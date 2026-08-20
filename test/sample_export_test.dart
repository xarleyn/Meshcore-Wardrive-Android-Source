import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/utils/sample_export.dart';

void main() {
  final earlier = Sample(
    id: 'earlier',
    position: const LatLng(55.75, 37.62),
    timestamp: DateTime.utc(2026, 1, 2, 3, 4, 5),
    geohash: 'ucftpv12',
    rssi: -92,
    snr: 7,
    pingSuccess: true,
    path: 'aabbccdd',
  );
  final later = Sample(
    id: 'later',
    position: const LatLng(59.93, 30.31),
    timestamp: DateTime.utc(2026, 1, 2, 4, 5, 6),
    geohash: 'udts2',
    pingSuccess: false,
  );
  final generatedAt = DateTime(2026, 7, 8, 9, 10);

  group('SampleExport.buildCsv', () {
    test('writes the current columns and optional values', () {
      final csv = SampleExport.buildCsv([earlier, later]);

      expect(
        csv,
        'id,lat,lon,timestamp,geohash,rssi,snr,pingSuccess,path\n'
        'earlier,55.75,37.62,2026-01-02T03:04:05.000Z,ucftpv12,'
        '-92,7,true,aabbccdd\n'
        'later,59.93,30.31,2026-01-02T04:05:06.000Z,udts2,,,'
        'false,\n',
      );
    });

    test('preserves input order', () {
      final csv = SampleExport.buildCsv([later, earlier]);

      expect(csv.indexOf('later,'), lessThan(csv.indexOf('earlier,')));
    });
  });

  group('SampleExport.buildGpx', () {
    test('writes GPX 1.1 sorted by timestamp', () {
      final gpx = SampleExport.buildGpx([
        later,
        earlier,
      ], generatedAt: generatedAt);

      expect(gpx, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(gpx, contains('<gpx version="1.1" creator="MeshCore Wardrive"'));
      expect(gpx, contains('<name>MeshCore Wardrive 2026-07-08</name>'));
      expect(gpx.indexOf('lat="55.75"'), lessThan(gpx.indexOf('lat="59.93"')));
      expect(gpx, contains('<time>2026-01-02T03:04:05.000Z</time>'));
      expect(gpx, endsWith('</gpx>\n'));
    });

    test('only writes signal description when RSSI is available', () {
      final gpx = SampleExport.buildGpx([
        earlier,
        later,
      ], generatedAt: generatedAt);

      expect(gpx, contains('<desc>RSSI: -92 dBm, SNR: 7 dB</desc>'));
      expect(gpx.split('<desc>'), hasLength(2));
    });
  });

  group('SampleExport.buildKml', () {
    test('writes the route sorted by timestamp', () {
      final kml = SampleExport.buildKml([
        later,
        earlier,
      ], generatedAt: generatedAt);

      expect(kml, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(kml, contains('<kml xmlns="http://www.opengis.net/kml/2.2">'));
      expect(kml, contains('<name>MeshCore Wardrive 2026-07-08</name>'));
      expect(
        kml.indexOf('37.62,55.75,0'),
        lessThan(kml.indexOf('30.31,59.93,0')),
      );
      expect(kml, endsWith('</kml>'));
    });

    test('writes ping placemarks and optional RSSI', () {
      final noPing = Sample(
        id: 'no-ping',
        position: const LatLng(1, 2),
        timestamp: DateTime.utc(2026),
        geohash: 's01mtw',
      );

      final kml = SampleExport.buildKml([
        later,
        noPing,
        earlier,
      ], generatedAt: generatedAt);

      expect(kml, contains('<styleUrl>#successStyle</styleUrl>'));
      expect(kml, contains('<description>Success RSSI:-92</description>'));
      expect(kml, contains('<styleUrl>#failStyle</styleUrl>'));
      expect(kml, contains('<description>Failed</description>'));
      expect(kml.split('<styleUrl>'), hasLength(3));
    });
  });
}
