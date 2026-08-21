import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/screens/map/layers/radio_position_layer.dart';
import 'package:meshcore_wardrive/services/radio_position_estimator.dart';

import '../helpers/l10n_harness.dart';

void main() {
  testWidgets('renders uncertainty area and delegates localized marker tap', (
    tester,
  ) async {
    String? tapMessage;
    const estimate = RadioPositionEstimate(
      position: LatLng(55.75, 37.62),
      uncertaintyMeters: 1250,
      repeaterCount: 4,
    );

    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: FlutterMap(
          options: MapOptions(
            initialCenter: estimate.position,
            initialZoom: 12,
          ),
          children: [
            RadioPositionLayer(
              estimate: estimate,
              onTap: (message) => tapMessage = message,
            ),
          ],
        ),
      ),
    );

    final polygonLayer = tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    expect(polygonLayer.polygons.single.points, hasLength(72));
    expect(
      find.bySemanticsLabel(l10n.mapApproxRadioPositionUncertainty('1.3 km')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.wifi_tethering));

    expect(tapMessage, l10n.mapApproxRadioPositionSnack(4, '1.3 km'));
  });
}
