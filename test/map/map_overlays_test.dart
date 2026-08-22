import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/map/widgets/delete_mode_banner.dart';
import 'package:meshcore_wardrive/screens/map/widgets/map_action_buttons.dart';
import 'package:meshcore_wardrive/screens/map/widgets/map_control_panel.dart';
import 'package:meshcore_wardrive/screens/map/widgets/map_quick_settings_panel.dart';
import 'package:meshcore_wardrive/services/carpeater_service.dart';
import 'package:meshcore_wardrive/services/lora_companion_service.dart';
import 'package:meshcore_wardrive/utils/compass_calibration.dart';

import '../helpers/l10n_harness.dart';

void main() {
  testWidgets('delete mode banner delegates exit', (tester) async {
    var exits = 0;
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Stack(children: [DeleteModeBanner(onExit: () => exits++)]),
      ),
    );

    expect(find.text(l10n.mapDeleteModeBanner), findsOneWidget);
    await tester.tap(find.text(l10n.mapExit));

    expect(exits, 1);
  });

  testWidgets('quick settings delegates close and value changes', (
    tester,
  ) async {
    var closes = 0;
    double? distance;
    int? timeout;
    String? mode;
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Stack(
          children: [
            MapQuickSettingsPanel(
              pingIntervalMeters: 805,
              discoveryTimeoutSeconds: 10,
              pingMode: 'time',
              onClose: () => closes++,
              onPingIntervalChanged: (value) => distance = value,
              onDiscoveryTimeoutChanged: (value) => timeout = value,
              onPingModeChanged: (value) => mode = value,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    expect(closes, 1);

    await tester.tap(find.text('0.5mi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50m').last);
    await tester.pumpAndSettle();
    expect(distance, 50);

    await tester.tap(find.text('10s'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5s').last);
    await tester.pumpAndSettle();
    expect(timeout, 5);

    await tester.tap(find.text(l10n.settingsPingModeTime));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsPingModeDistance).last);
    await tester.pumpAndSettle();
    expect(mode, 'distance');
  });

  testWidgets('map action buttons expose map callbacks and calibration state', (
    tester,
  ) async {
    var compassPresses = 0;
    var compassLongPresses = 0;
    var locationPresses = 0;

    await pumpWithL10n(
      tester,
      Scaffold(
        floatingActionButton: MapActionButtons(
          isTracking: false,
          compassInUse: true,
          lockRotationNorth: false,
          followHeading: false,
          compassAccuracyStatus: CompassAccuracyStatus.needsCalibration,
          followLocation: false,
          onCompassPressed: () => compassPresses++,
          onCompassLongPressed: () => compassLongPresses++,
          onLocationPressed: () => locationPresses++,
          onToggleTracking: () {},
          onStartFreshSession: () {},
          onToggleQuickSettings: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.error), findsOneWidget);
    final miniButtons = find.byWidgetPredicate(
      (widget) => widget is FloatingActionButton && widget.mini,
    );
    await tester.tap(miniButtons.first);
    await tester.pump();
    final compassGesture = tester.widget<GestureDetector>(
      find
          .ancestor(
            of: miniButtons.first,
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    compassGesture.onLongPress!();
    await tester.tap(miniButtons.last);

    expect(compassPresses, 1);
    expect(compassLongPresses, 1);
    expect(locationPresses, 1);
  });

  testWidgets('control panel renders status and delegates connection actions', (
    tester,
  ) async {
    var connects = 0;
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Stack(
          children: [
            MapControlPanel(
              loraConnected: false,
              isConnecting: false,
              connectionType: ConnectionType.none,
              batteryPercent: null,
              sampleCount: 42,
              isTracking: false,
              totalDistance: 0,
              currentSpeed: 0,
              distanceUnit: 'km',
              carpeaterEnabled: false,
              carpeaterState: CarpeaterState.disabled,
              ductingLabel: null,
              ductingColor: null,
              batterySaverActive: false,
              onConnect: () => connects++,
              onDisconnect: () {},
              onManualPing: () {},
              onCarpeaterRetry: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.text(l10n.mapNoLora), findsOneWidget);
    expect(find.text(l10n.mapSamplesCount('42')), findsOneWidget);
    await tester.tap(find.text(l10n.mapConnect));

    expect(connects, 1);
  });
}
