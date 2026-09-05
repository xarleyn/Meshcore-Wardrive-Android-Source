import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/screens/map/map_screen_controller.dart';
import 'package:meshcore_wardrive/screens/map/tracking_flow.dart';
import 'package:meshcore_wardrive/services/location_service.dart';
import 'package:meshcore_wardrive/services/settings_service.dart';
import 'package:meshcore_wardrive/utils/session_map_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/l10n_harness.dart';

/// LocationService double overriding only the members the start path
/// touches; the real constructor performs no platform work before first use.
class _StubLocationService extends LocationService {
  bool autoPingEnabled = false;
  bool carpeaterModeEnabled = false;
  bool carpeaterStartSucceeds = true;

  @override
  Future<bool> startTracking() async => true;

  @override
  void enableAutoPing() => autoPingEnabled = true;

  @override
  void disableAutoPing() => autoPingEnabled = false;

  @override
  void setCarpeaterMode(bool enabled) => carpeaterModeEnabled = enabled;

  @override
  Future<bool> startCarpeater() async => carpeaterStartSucceeds;
}

class _EmptyStore implements MapDataStore {
  @override
  Future<int> getSampleCount() async => 0;

  @override
  Future<List<Sample>> getAllSamples() async => const [];

  @override
  Future<void> deleteSample(String sampleId) async {}

  @override
  Future<int> deleteSamplesByGeohash(String geohashPrefix) async => 0;

  @override
  Future<List<WSession>> getAllSessions() async => const [];

  @override
  Future<void> deleteSession(int id) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<TrackingFlow> pumpFlow(
    WidgetTester tester, {
    required _StubLocationService locationService,
    required bool Function() loraConnected,
    required bool Function() carpeaterEnabled,
    required void Function(bool tracking, bool? autoPing) onTrackingState,
  }) async {
    TrackingFlow? flow;
    await pumpWithL10n(
      tester,
      Builder(
        builder: (context) {
          flow = TrackingFlow(
            context: context,
            onShowSnackBar: (_) {},
            locationService: locationService,
            settingsService: SettingsService(),
            mapDataController: MapScreenController(store: _EmptyStore()),
            isTracking: () => false,
            currentSessionView: () => const SessionMapView.all(),
            loraConnected: loraConnected,
            carpeaterEnabled: carpeaterEnabled,
            setTrackingState: onTrackingState,
            applySessionView: (_) {},
            prepareAndroidTracking: () async => true,
          );
          return const SizedBox.shrink();
        },
      ),
    );
    return flow!;
  }

  testWidgets(
    'startTracking enables auto-ping when the radio connects after the flow was built',
    (tester) async {
      final locationService = _StubLocationService();
      var loraConnected = false;
      final trackingCalls = <(bool, bool?)>[];
      final flow = await pumpFlow(
        tester,
        locationService: locationService,
        loraConnected: () => loraConnected,
        carpeaterEnabled: () => false,
        onTrackingState: (tracking, autoPing) =>
            trackingCalls.add((tracking, autoPing)),
      );

      // The companion radio connects after the flow was constructed; the
      // flags must be re-read at start time, not frozen at build time.
      loraConnected = true;
      await flow.startTracking();

      expect(locationService.autoPingEnabled, isTrue);
      expect(trackingCalls.last, (true, true));
    },
  );

  testWidgets(
    'startTracking prefers Carpeater while connected and the setting is on',
    (tester) async {
      final locationService = _StubLocationService();
      final trackingCalls = <(bool, bool?)>[];
      final flow = await pumpFlow(
        tester,
        locationService: locationService,
        loraConnected: () => true,
        carpeaterEnabled: () => true,
        onTrackingState: (tracking, autoPing) =>
            trackingCalls.add((tracking, autoPing)),
      );

      await flow.startTracking();

      expect(locationService.carpeaterModeEnabled, isTrue);
      expect(locationService.autoPingEnabled, isFalse);
      expect(trackingCalls.last, (true, false));
    },
  );

  testWidgets(
    'startTracking stays plain when the radio disconnects after the flow was built',
    (tester) async {
      final locationService = _StubLocationService();
      var loraConnected = true;
      final trackingCalls = <(bool, bool?)>[];
      final flow = await pumpFlow(
        tester,
        locationService: locationService,
        loraConnected: () => loraConnected,
        carpeaterEnabled: () => false,
        onTrackingState: (tracking, autoPing) =>
            trackingCalls.add((tracking, autoPing)),
      );

      loraConnected = false;
      await flow.startTracking();

      expect(locationService.autoPingEnabled, isFalse);
      expect(trackingCalls.last, (true, null));
    },
  );
}
