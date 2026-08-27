import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/screens/map/layers/zone_overlay_layer.dart';

void main() {
  testWidgets('renders every zone center and configured radius', (
    tester,
  ) async {
    const zones = [
      ZoneOverlay(center: LatLng(55, 37), radiusMeters: 500),
      ZoneOverlay(center: LatLng(56, 38), radiusMeters: 1000),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: FlutterMap(
          options: MapOptions(initialCenter: LatLng(55, 37)),
          children: [ZoneOverlayLayer(zones: zones, color: Colors.deepOrange)],
        ),
      ),
    );

    final polygonLayer = tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    expect(polygonLayer.polygons, hasLength(2));
    expect(polygonLayer.polygons.first.points, hasLength(48));

    final circleLayer = tester.widget<CircleLayer>(find.byType(CircleLayer));
    expect(circleLayer.circles, hasLength(2));
    expect(circleLayer.circles.first.point, zones.first.center);
    expect(circleLayer.circles.last.point, zones.last.center);
  });
}
