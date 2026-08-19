import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/models/impossible_zone.dart';

void main() {
  const airport = ImpossibleZone(
    lat: 55.410,
    lon: 37.902,
    radiusMeters: 1000,
    label: 'Airport',
  );

  group('ImpossibleZone.contains', () {
    test('treats the center as inside', () {
      expect(airport.contains(55.410, 37.902), isTrue);
    });

    test('treats a point well inside the radius as inside', () {
      // ~111 m north of the center at this latitude.
      expect(airport.contains(55.411, 37.902), isTrue);
    });

    test('treats a point well outside the radius as outside', () {
      expect(airport.contains(55.430, 37.902), isFalse);
    });
  });

  group('ImpossibleZone.containing', () {
    test('returns null when the list is empty', () {
      expect(ImpossibleZone.containing(const [], 55.410, 37.902), isNull);
    });

    test('returns the first matching zone', () {
      const water = ImpossibleZone(
        lat: 59.95,
        lon: 30.15,
        radiusMeters: 500,
        label: 'Water',
      );

      final match = ImpossibleZone.containing(
        const [airport, water],
        59.95,
        30.15,
      );

      expect(match, isNotNull);
      expect(match!.label, 'Water');
    });
  });

  group('ImpossibleZone.rejectionReason', () {
    test('describes an unlabeled zone', () {
      const zone = ImpossibleZone(lat: 0, lon: 0, radiusMeters: 100);

      expect(zone.rejectionReason, 'inside impossible zone');
    });

    test('includes the label', () {
      expect(airport.rejectionReason, 'inside impossible zone: Airport');
    });
  });

  group('ImpossibleZone.fromMap', () {
    test('reads sqlite row fields', () {
      final zone = ImpossibleZone.fromMap({
        'id': 3,
        'lat': 55.41,
        'lon': 37.902,
        'radius_meters': 1000,
        'label': 'Airport',
      });

      expect(zone.id, 3);
      expect(zone.lat, 55.41);
      expect(zone.lon, 37.902);
      expect(zone.radiusMeters, 1000);
      expect(zone.label, 'Airport');
    });
  });
}
