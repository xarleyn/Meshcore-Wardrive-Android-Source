import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meshcore_wardrive/services/location_quality_filter.dart';

void main() {
  group('LocationQualityFilter', () {
    test('accepts an accurate Wi-Fi or GPS fix at road speed', () {
      final filter = LocationQualityFilter();

      expect(
        filter.rejectionReason(
          _position(accuracy: 45, altitude: 620, speed: 25),
        ),
        isNull,
      );
    });

    test('rejects an inaccurate network fix', () {
      final filter = LocationQualityFilter();

      expect(
        filter.rejectionReason(_position(accuracy: 400)),
        contains('horizontal accuracy'),
      );
    });

    test('rejects a fix Android reports as mocked', () {
      final filter = LocationQualityFilter();

      expect(
        filter.rejectionReason(_position(isMocked: true)),
        contains('mocked'),
      );
    });

    test('rejects a probable flight without banning mountain roads', () {
      final filter = LocationQualityFilter();

      expect(
        filter.rejectionReason(_position(altitude: 800, speed: 60)),
        contains('probable flight'),
      );
      expect(
        filter.rejectionReason(_position(altitude: 800, speed: 25)),
        isNull,
      );
    });

    test('uses movement between fixes when reported speed is unavailable', () {
      final filter = LocationQualityFilter();
      final start = DateTime.utc(2026, 1, 1);
      filter.accept(_position(timestamp: start, altitude: 100, speed: 0));

      final reason = filter.rejectionReason(
        _position(
          latitude: 55.01,
          timestamp: start.add(const Duration(seconds: 5)),
          altitude: 900,
          speed: 0,
        ),
      );

      expect(reason, contains('probable flight'));
    });
  });
}

Position _position({
  double latitude = 55,
  double longitude = 32,
  DateTime? timestamp,
  double accuracy = 10,
  double altitude = 100,
  double speed = 10,
  bool isMocked = false,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? DateTime.utc(2026, 1, 1),
    accuracy: accuracy,
    altitude: altitude,
    altitudeAccuracy: 5,
    heading: 0,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 1,
    isMocked: isMocked,
  );
}
