import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/utils/geohash_utils.dart';
import 'package:meshcore_wardrive/utils/initial_map_camera.dart';

void main() {
  group('InitialMapCamera.fromPositions', () {
    test('returns null when there are no measurements', () {
      expect(InitialMapCamera.fromPositions(const []), isNull);
    });

    test('centers on a single measurement at city zoom', () {
      const moscow = LatLng(55.7558, 37.6173);

      final camera = InitialMapCamera.fromPositions([moscow]);

      expect(camera, isNotNull);
      expect(camera!.center.latitude, closeTo(moscow.latitude, 1e-9));
      expect(camera.center.longitude, closeTo(moscow.longitude, 1e-9));
      expect(camera.zoom, InitialMapCamera.cityZoom);
    });

    test('uses the centroid of several measurements', () {
      const north = LatLng(56.0, 37.6);
      const south = LatLng(55.5, 37.6);

      final camera = InitialMapCamera.fromPositions([north, south]);

      expect(camera, isNotNull);
      expect(camera!.center.latitude, closeTo(55.75, 1e-9));
      expect(camera.center.longitude, closeTo(37.6, 1e-9));
    });

    test('wraps longitude when averaging points across the antimeridian', () {
      const east = LatLng(0.0, 170.0);
      const west = LatLng(0.0, -170.0);

      final camera = InitialMapCamera.fromPositions([east, west]);

      expect(camera, isNotNull);
      expect(camera!.center.latitude, closeTo(0.0, 1e-9));
      expect(camera.center.longitude.abs(), closeTo(180.0, 0.5));
    });

    test('keeps city zoom for a tight neighbourhood cluster', () {
      const a = LatLng(55.75, 37.62);
      const b = LatLng(55.76, 37.63);

      final camera = InitialMapCamera.fromPositions([a, b]);

      expect(camera, isNotNull);
      expect(camera!.zoom, InitialMapCamera.cityZoom);
    });

    test('zooms out when measurements span more than a city', () {
      const west = LatLng(55.6, 37.2);
      const east = LatLng(55.9, 38.1);

      final camera = InitialMapCamera.fromPositions([west, east]);

      expect(camera, isNotNull);
      expect(camera!.zoom, lessThan(InitialMapCamera.cityZoom));
      expect(camera.zoom, greaterThanOrEqualTo(InitialMapCamera.minZoom));
    });

    test('does not zoom out past the map minimum', () {
      const west = LatLng(0.0, -80.0);
      const east = LatLng(0.0, 80.0);

      final camera = InitialMapCamera.fromPositions([west, east]);

      expect(camera, isNotNull);
      expect(camera!.zoom, InitialMapCamera.minZoom);
    });
  });

  group('InitialMapCamera.fallback', () {
    test('keeps the historical default when nothing is known yet', () {
      expect(InitialMapCamera.fallbackCenter, GeohashUtils.centerPos);
      expect(InitialMapCamera.fallbackZoom, 13.0);
    });
  });
}
