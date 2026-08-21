import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/map_entity_dialogs.dart';

import '../helpers/l10n_harness.dart';

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
}
