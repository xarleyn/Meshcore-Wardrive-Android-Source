import 'package:intl/intl.dart';
import 'package:meshcore_wardrive/models/models.dart';

/// Builds portable text exports for wardrive samples.
abstract final class SampleExport {
  static String buildCsv(List<Sample> samples) {
    final buffer = StringBuffer();
    buffer.writeln('id,lat,lon,timestamp,geohash,rssi,snr,pingSuccess,path');
    for (final sample in samples) {
      buffer.writeln(
        '${sample.id},${sample.position.latitude},'
        '${sample.position.longitude},${sample.timestamp.toIso8601String()},'
        '${sample.geohash},${sample.rssi ?? ''},${sample.snr ?? ''},'
        '${sample.pingSuccess ?? ''},${sample.path ?? ''}',
      );
    }
    return buffer.toString();
  }

  static String buildGpx(List<Sample> samples, {DateTime? generatedAt}) {
    final sorted = List<Sample>.from(samples)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final generatedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(generatedAt ?? DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="MeshCore Wardrive"');
    buffer.writeln('  xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>MeshCore Wardrive $generatedDate</name>');
    buffer.writeln('    <trkseg>');
    for (final sample in sorted) {
      buffer.writeln(
        '      <trkpt lat="${sample.position.latitude}" '
        'lon="${sample.position.longitude}">',
      );
      buffer.writeln(
        '        <time>${sample.timestamp.toUtc().toIso8601String()}</time>',
      );
      if (sample.rssi != null) {
        buffer.writeln(
          '        <desc>RSSI: ${sample.rssi} dBm, '
          'SNR: ${sample.snr} dB</desc>',
        );
      }
      buffer.writeln('      </trkpt>');
    }
    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');
    return buffer.toString();
  }

  static String buildKml(List<Sample> samples, {DateTime? generatedAt}) {
    final sorted = List<Sample>.from(samples)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final generatedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(generatedAt ?? DateTime.now());

    final coords = sorted
        .map(
          (sample) =>
              '${sample.position.longitude},${sample.position.latitude},0',
        )
        .join('\n            ');

    final placemarks = StringBuffer();
    for (final sample in sorted.where((sample) => sample.pingSuccess != null)) {
      final icon = sample.pingSuccess == true ? '#successStyle' : '#failStyle';
      placemarks.writeln('    <Placemark>');
      placemarks.writeln('      <styleUrl>$icon</styleUrl>');
      placemarks.writeln(
        '      <description>'
        '${sample.pingSuccess == true ? 'Success' : 'Failed'}'
        '${sample.rssi != null ? ' RSSI:${sample.rssi}' : ''}'
        '</description>',
      );
      placemarks.writeln(
        '      <Point><coordinates>${sample.position.longitude},'
        '${sample.position.latitude},0</coordinates></Point>',
      );
      placemarks.writeln('    </Placemark>');
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>MeshCore Wardrive $generatedDate</name>
    <Style id="successStyle"><IconStyle><color>ff00ff00</color></IconStyle></Style>
    <Style id="failStyle"><IconStyle><color>ff0000ff</color></IconStyle></Style>
    <Placemark>
      <name>Route Trail</name>
      <LineString>
        <coordinates>
            $coords
        </coordinates>
      </LineString>
    </Placemark>
$placemarks  </Document>
</kml>''';
  }
}
