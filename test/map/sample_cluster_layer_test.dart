import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/screens/map/layers/sample_cluster_layer.dart';
import 'package:meshcore_wardrive/services/map_lod_service.dart';

void main() {
  final sample = Sample(
    id: 'sample',
    position: const LatLng(55, 37),
    timestamp: DateTime.utc(2026),
    geohash: 'ucfv',
    pingSuccess: true,
  );

  testWidgets('uses the fixed radius when sample sizing is overridden', (
    tester,
  ) async {
    final hitNotifier = ValueNotifier<LayerHitResult<SampleCluster>?>(null);
    addTearDown(hitNotifier.dispose);
    final cluster = SampleCluster(
      id: 'ucfv',
      position: sample.position,
      sampleCount: 1,
      successfulCount: 1,
      failedCount: 0,
      gpsOnlyCount: 0,
      newestSample: sample,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FlutterMap(
          options: MapOptions(initialCenter: sample.position),
          children: [
            SampleClusterLayer(
              clusters: [cluster],
              colorBlindMode: 'none',
              fixedRadius: 14,
              hitNotifier: hitNotifier,
              onClusterTap: (_) {},
            ),
          ],
        ),
      ),
    );

    final layer = tester.widget<CircleLayer<SampleCluster>>(
      find.byType(CircleLayer<SampleCluster>),
    );
    expect(layer.circles.single.radius, 14);
  });
}
