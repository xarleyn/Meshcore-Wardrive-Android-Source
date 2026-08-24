import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/l10n/generated/app_localizations.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/map_entity_dialogs.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/sample_details_sheet.dart';
import 'package:meshcore_wardrive/utils/ping_burst.dart';

import '../helpers/l10n_harness.dart';

Sample _sample(
  String id, {
  DateTime? timestamp,
  String? path,
  int? rssi,
  bool? pingSuccess = true,
}) {
  return Sample(
    id: id,
    position: const LatLng(55.75, 37.62),
    timestamp: timestamp ?? DateTime.utc(2026, 8, 13, 12),
    path: path,
    geohash: 'ucftpv1',
    rssi: rssi,
    snr: rssi == null ? null : -rssi ~/ 10,
    pingSuccess: pingSuccess,
  );
}

Future<AppLocalizations> _pumpDialog(
  WidgetTester tester, {
  required Sample sample,
  required List<Sample> responses,
}) async {
  final l10n = await pumpWithL10n(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => SampleInfoDialog(
                sample: sample,
                responses: responses,
                repeaterDisplay: 'AABBCCDD',
                resolveRepeaterName: (nodeId) =>
                    nodeId == null ? null : 'Named $nodeId',
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return l10n;
}

void main() {
  testWidgets('details link opens a sheet listing the burst responders', (
    tester,
  ) async {
    final at = DateTime.utc(2026, 8, 13, 12);
    final tapped = _sample('a', timestamp: at, path: 'AABBCCDD1122', rssi: -90);
    final stronger = _sample(
      'b',
      timestamp: at.add(const Duration(milliseconds: 40)),
      path: 'BBBBCCDD2211',
      rssi: -78,
    );
    final responses = PingBurst.responsesFor(tapped, [tapped, stronger]);
    final l10n = await _pumpDialog(
      tester,
      sample: tapped,
      responses: responses,
    );

    expect(find.text(l10n.mapMoreDetails), findsOneWidget);
    await tester.tap(find.text(l10n.mapMoreDetails));
    await tester.pumpAndSettle();

    expect(find.text(l10n.mapSampleDetailsTitle), findsOneWidget);
    expect(find.text(l10n.mapRespondersTitle(2)), findsOneWidget);
    expect(find.text(l10n.mapBestSignal('-78 dBm')), findsOneWidget);
    // Responder names come from the injected resolver.
    expect(find.text('Named AABBCCDD1122'), findsOneWidget);
    expect(find.text('Named BBBBCCDD2211'), findsOneWidget);
    // The tapped measurement is marked inside the list.
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.text(l10n.mapNoResponders), findsNothing);
  });

  testWidgets('failed ping sheet explains that nobody responded', (
    tester,
  ) async {
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: SampleDetailsSheet(
          sample: _sample('a', path: null, rssi: null, pingSuccess: false),
          responses: const [],
        ),
      ),
    );

    expect(find.text(l10n.mapNoResponders), findsOneWidget);
    expect(find.text(l10n.mapRespondersTitle(0)), findsNothing);
  });

  testWidgets('GPS-only samples hide the responder section', (tester) async {
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: SampleDetailsSheet(
          sample: _sample('a', path: null, rssi: null, pingSuccess: null),
          responses: const [],
        ),
      ),
    );

    expect(find.text(l10n.mapNoResponders), findsNothing);
    expect(find.text(l10n.mapStatusGpsOnly), findsOneWidget);
  });
}
