import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/marker_dialogs.dart';

import 'helpers/l10n_harness.dart';

void main() {
  testWidgets('map long press sheet returns the selected typed action', (
    tester,
  ) async {
    MapLongPressAction? result;
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showModalBottomSheet<MapLongPressAction>(
                context: context,
                builder: (context) => const MapLongPressActionSheet(),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsAddImpossibleZone));
    await tester.pumpAndSettle();

    expect(result, MapLongPressAction.impossibleZone);
  });

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
    await tester.enterText(find.byKey(const Key('zone_dialog_label')), 'Home');
    await tester.enterText(find.byKey(const Key('zone_dialog_radius')), '2000');
    await tester.tap(find.text(l10n.settingsAddZone));
    await tester.pumpAndSettle();

    expect(result?.radiusMeters, 2000);
    expect(result?.label, 'Home');
  });

  testWidgets('impossible zone dialog returns center radius and label', (
    tester,
  ) async {
    ImpossibleZoneDraft? result;
    final center = LatLng(55.75, 37.62);
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<ImpossibleZoneDraft>(
                context: context,
                builder: (context) => AddImpossibleZoneDialog(center: center),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('zone_dialog_label')),
      'Airport',
    );
    await tester.enterText(find.byKey(const Key('zone_dialog_radius')), '5000');
    await tester.tap(find.text(l10n.settingsAddZone));
    await tester.pumpAndSettle();

    expect(result?.center, center);
    expect(result?.radiusMeters, 5000);
    expect(result?.label, 'Airport');
  });

  testWidgets('zone dialog clamps the typed radius to the allowed range', (
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
    await tester.enterText(
      find.byKey(const Key('zone_dialog_radius')),
      '99999',
    );
    await tester.pump();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, 10000);

    await tester.tap(find.text(l10n.settingsAddZone));
    await tester.pumpAndSettle();

    expect(result?.radiusMeters, 10000);
  });

  testWidgets('zone dialog slider updates the radius text field', (
    tester,
  ) async {
    await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<PrivacyZoneDraft>(
              context: context,
              builder: (context) =>
                  const AddPrivacyZoneDialog(center: LatLng(55.75, 37.62)),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('zone_dialog_radius')))
          .controller!
          .text,
      '1000',
    );

    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();

    final text = tester
        .widget<TextField>(find.byKey(const Key('zone_dialog_radius')))
        .controller!
        .text;
    expect(int.parse(text), greaterThan(1000));
  });
}
