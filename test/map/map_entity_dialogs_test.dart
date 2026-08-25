import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/map_entity_dialogs.dart';
import 'package:meshcore_wardrive/services/map_lod_service.dart';

import '../helpers/l10n_harness.dart';

Sample _sample(String id, {String? path, int? rssi, bool? pingSuccess}) {
  return Sample(
    id: id,
    position: const LatLng(55.75, 37.62),
    timestamp: DateTime.utc(2026, 8, 13, 12),
    path: path,
    geohash: 'ucftpv11',
    rssi: rssi,
    pingSuccess: pingSuccess,
  );
}

void main() {
  testWidgets('repeater dialog returns a typed action', (tester) async {
    RepeaterInfoAction? result;
    final repeater = Repeater(
      id: 'AABBCCDDEEFF',
      position: const LatLng(55.75, 37.62),
      name: 'Test repeater',
    );
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<RepeaterInfoAction>(
                context: context,
                builder: (context) => RepeaterInfoDialog(repeater: repeater),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.mapFilterByThis));
    await tester.pumpAndSettle();

    expect(result, RepeaterInfoAction.filter);
  });

  testWidgets('coverage dialog formats aggregate values and repeater IDs', (
    tester,
  ) async {
    final coverage = Coverage(
      id: 'ucftpv1',
      position: const LatLng(55.75, 37.62),
      received: 3,
      lost: 1,
      repeaters: ['AABBCCDDEE', '1122334455'],
    );
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(body: CoverageInfoDialog(coverage: coverage)),
    );

    expect(find.text('75%'), findsOneWidget);
    expect(find.text('1122, AABB'), findsOneWidget);
    expect(find.text(l10n.mapCoverageSquareInfo), findsOneWidget);
  });

  testWidgets('cluster dialog opens the measurement list sheet', (
    tester,
  ) async {
    final samples = [
      _sample('a', path: 'AABBCCDD1122', rssi: -80, pingSuccess: true),
      _sample('b', path: null, rssi: null, pingSuccess: null),
      _sample('c', path: null, rssi: null, pingSuccess: false),
    ];
    final cluster = SampleCluster(
      id: 'ucftpv1',
      position: const LatLng(55.75, 37.62),
      sampleCount: 3,
      successfulCount: 1,
      failedCount: 1,
      gpsOnlyCount: 1,
      newestSample: samples.first,
      samples: samples,
    );
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => SampleClusterInfoDialog(
                cluster: cluster,
                resolveRepeaterName: (nodeId) =>
                    nodeId == null ? null : 'Named $nodeId',
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.mapMoreDetails), findsOneWidget);

    await tester.tap(find.text(l10n.mapMoreDetails));
    await tester.pumpAndSettle();

    expect(find.text(l10n.mapMeasurementsTitle(3)), findsOneWidget);
    // Rows resolve repeater names and keep the GPS-only/failed labels.
    expect(find.text('Named AABBCCDD1122'), findsOneWidget);
    expect(find.text(l10n.mapStatusGpsOnly), findsOneWidget);
    expect(find.text(l10n.mapStatusFailed), findsOneWidget);
  });
}
