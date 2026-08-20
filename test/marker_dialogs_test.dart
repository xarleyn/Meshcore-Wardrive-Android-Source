import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/marker_dialogs.dart';

import 'helpers/l10n_harness.dart';

void main() {
  testWidgets('planned marker dialog returns a typed delete action', (
    tester,
  ) async {
    PlannedMarkerAction? result;
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<PlannedMarkerAction>(
                context: context,
                builder: (context) => PlannedMarkerInfoDialog(
                  latitude: 55.75,
                  longitude: 37.62,
                  createdAt: DateTime(2026, 8, 20),
                  label: 'Future repeater',
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
    await tester.tap(find.text(l10n.mapDelete));
    await tester.pumpAndSettle();

    expect(result, PlannedMarkerAction.delete);
  });

  testWidgets('privacy zone dialog returns radius and optional label', (
    tester,
  ) async {
    PrivacyZoneDraft? result;
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<PrivacyZoneDraft>(
                context: context,
                builder: (context) =>
                    const AddPrivacyZoneDialog(center: LatLng(55.75, 37.62)),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Home');
    await tester.tap(find.text(l10n.settingsRadius2km));
    await tester.pump();
    await tester.tap(find.text(l10n.settingsAddZone));
    await tester.pumpAndSettle();

    expect(result?.radiusMeters, 2000);
    expect(result?.label, 'Home');
  });
}
