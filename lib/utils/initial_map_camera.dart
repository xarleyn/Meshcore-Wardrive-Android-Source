import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'geohash_utils.dart';

/// Fallback camera used before GPS is known.
///
/// When the user already has measurements, the map opens on their centroid at
/// a city-scale zoom. Spread-out samples zoom out just enough to fit. With no
/// points, callers keep [fallbackCenter] and [fallbackZoom].
class InitialMapCamera {
  static final LatLng fallbackCenter = GeohashUtils.centerPos;
  static const double fallbackZoom = 13.0;
  static const double cityZoom = 11.0;
  static const double minZoom = 3.0;
  static const double _fitPadding = 1.4;

  final LatLng center;
  final double zoom;

  const InitialMapCamera({required this.center, required this.zoom});

  static InitialMapCamera? fromPositions(Iterable<LatLng> positions) {
    final points = positions.toList();
    if (points.isEmpty) return null;

    return InitialMapCamera(center: _centroid(points), zoom: _zoomFor(points));
  }

  static LatLng _centroid(List<LatLng> points) {
    var latitudeSum = 0.0;
    var longitudeX = 0.0;
    var longitudeY = 0.0;

    for (final point in points) {
      final longitudeRadians = point.longitude * math.pi / 180;
      latitudeSum += point.latitude;
      longitudeX += math.cos(longitudeRadians);
      longitudeY += math.sin(longitudeRadians);
    }

    return LatLng(
      latitudeSum / points.length,
      math.atan2(longitudeY, longitudeX) * 180 / math.pi,
    );
  }

  static double _zoomFor(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }

    final latSpan = maxLat - minLat;
    var lonSpan = maxLon - minLon;
    if (lonSpan > 180) {
      lonSpan = 360 - lonSpan;
    }

    final span = math.max(latSpan, lonSpan);
    if (span < 1e-6) return cityZoom;

    final fitted = math.log(360.0 / (span * _fitPadding)) / math.ln2;
    return fitted.clamp(minZoom, cityZoom);
  }
}
