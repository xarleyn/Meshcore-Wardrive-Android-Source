import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/services/database_service.dart';

void main() {
  Map<String, dynamic> zone(double lat, double lon, double radiusMeters) => {
    'lat': lat,
    'lon': lon,
    'radius_meters': radiusMeters,
  };

  Sample sample(double lat, double lon) => Sample(
    id: 'sample_${lat}_$lon',
    position: LatLng(lat, lon),
    timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    geohash: 'c23nb2q2',
  );

  group('DatabaseService.isInsidePrivacyZone', () {
    test('accepts the zone center', () {
      expect(
        DatabaseService.isInsidePrivacyZone(
          zone(47.7, -122.4, 500),
          47.7,
          -122.4,
        ),
        isTrue,
      );
    });

    test('accepts a point within the radius', () {
      // 0.001 degree of latitude is roughly 111 meters.
      expect(
        DatabaseService.isInsidePrivacyZone(
          zone(47.7, -122.4, 500),
          47.701,
          -122.4,
        ),
        isTrue,
      );
    });

    test('rejects a point beyond the radius', () {
      expect(
        DatabaseService.isInsidePrivacyZone(
          zone(47.7, -122.4, 500),
          47.71,
          -122.4,
        ),
        isFalse,
      );
    });
  });

  group('DatabaseService.filterSamplesByPrivacyZones', () {
    test('returns the same list when there are no zones', () {
      final samples = [sample(47.7, -122.4), sample(47.8, -122.5)];
      expect(
        DatabaseService.filterSamplesByPrivacyZones(samples, []),
        same(samples),
      );
    });

    test('drops samples inside a zone and keeps the rest', () {
      final samples = [sample(47.7, -122.4), sample(47.75, -122.4)];
      final filtered = DatabaseService.filterSamplesByPrivacyZones(samples, [
        zone(47.7, -122.4, 500),
      ]);
      expect(filtered, hasLength(1));
      expect(filtered.single.position.latitude, 47.75);
    });

    test('checks every zone', () {
      final samples = [sample(47.7, -122.4), sample(47.8, -122.4)];
      final filtered = DatabaseService.filterSamplesByPrivacyZones(samples, [
        zone(47.7, -122.4, 500),
        zone(47.8, -122.4, 500),
      ]);
      expect(filtered, isEmpty);
    });
  });
}
