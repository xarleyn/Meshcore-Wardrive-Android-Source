import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/coverage_tools_dialogs.dart';

import '../helpers/l10n_harness.dart';

void main() {
  test('coverage gaps excludes GPS-only cells and sorts worst first', () {
    final gpsOnly = _coverage('gps', received: 0, lost: 0);
    final weak = _coverage('weak', received: 2, lost: 8);
    final dead = _coverage('dead', received: 0, lost: 4);
    final healthy = _coverage('healthy', received: 8, lost: 2);

    final result = coverageGaps([gpsOnly, weak, dead, healthy]);

    expect(result.map((coverage) => coverage.id), ['dead', 'weak']);
  });

  testWidgets('repeater filter dialog returns a typed selection', (
    tester,
  ) async {
    RepeaterFilterResult? result;
    const id = 'AABBCCDDEEFF';
    await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<RepeaterFilterResult>(
                context: context,
                builder: (context) => RepeaterFilterDialog(
                  repeaterIds: const [id],
                  repeaters: [
                    Repeater(
                      id: id,
                      position: const LatLng(55.75, 37.62),
                      name: 'Tower',
                    ),
                  ],
                  selectedId: null,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tower'));
    await tester.pumpAndSettle();

    expect(result?.action, RepeaterFilterAction.select);
    expect(result?.repeaterId, id);
  });
}

Coverage _coverage(
  String id, {
  required double received,
  required double lost,
}) {
  return Coverage(
    id: id,
    position: const LatLng(55.75, 37.62),
    received: received,
    lost: lost,
    repeaters: const [],
  );
}
