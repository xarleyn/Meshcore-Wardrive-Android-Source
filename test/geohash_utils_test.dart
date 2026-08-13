import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/utils/geohash_utils.dart';

void main() {
  group('GeohashUtils', () {
    test('uses the requested geohash precision', () {
      expect(GeohashUtils.sampleKey(47.7776, -122.4247), hasLength(8));
      expect(GeohashUtils.coverageKey(47.7776, -122.4247), hasLength(6));
      expect(
        GeohashUtils.coverageKey(47.7776, -122.4247, precision: 7),
        hasLength(7),
      );
    });

    test('decodes a position near the encoded coordinates', () {
      final hash = GeohashUtils.sampleKey(47.7776, -122.4247);
      final decoded = GeohashUtils.posFromHash(hash);

      expect(decoded.latitude, closeTo(47.7776, 0.001));
      expect(decoded.longitude, closeTo(-122.4247, 0.001));
    });

    test('calculates haversine distance in miles', () {
      const origin = LatLng(0, 0);

      expect(GeohashUtils.haversineMiles(origin, origin), closeTo(0, 1e-9));
      expect(
        GeohashUtils.haversineMiles(origin, const LatLng(0, 1)),
        closeTo(69.09, 0.1),
      );
    });

    test('validates coordinate bounds', () {
      expect(GeohashUtils.isValidLocation(const LatLng(90, 180)), isTrue);
      expect(GeohashUtils.isValidLocation(const LatLng(-90, -180)), isTrue);
      expect(GeohashUtils.isValidLocation(const LatLng(91, 0)), isFalse);
      expect(GeohashUtils.isValidLocation(const LatLng(0, -181)), isFalse);
    });
  });
}
