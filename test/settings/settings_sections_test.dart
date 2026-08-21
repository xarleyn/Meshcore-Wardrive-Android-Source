import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/settings/sections/carpeater_section.dart';
import 'package:meshcore_wardrive/screens/settings/sections/feedback_section.dart';
import 'package:meshcore_wardrive/screens/settings/sections/map_display_section.dart';

import '../helpers/l10n_harness.dart';

void main() {
  testWidgets('feedback section delegates switch changes', (tester) async {
    bool? soundEnabled;
    await pumpWithL10n(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: ListView(
            children: buildFeedbackSettings(
              context,
              values: const FeedbackSettingsValues(
                soundEnabled: false,
                vibrationEnabled: false,
                deadZoneAlertsEnabled: false,
                newRepeaterAlertsEnabled: false,
              ),
              onSoundChanged: (value) => soundEnabled = value,
              onVibrationChanged: (_) {},
              onDeadZoneAlertsChanged: (_) {},
              onNewRepeaterAlertsChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SwitchListTile).first);

    expect(soundEnabled, isTrue);
  });

  testWidgets('carpeater section hides details and delegates enable', (
    tester,
  ) async {
    bool? enabled;
    await pumpWithL10n(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: ListView(
            children: buildCarpeaterSettings(
              context,
              values: const CarpeaterSettingsValues(
                enabled: false,
                repeaterId: null,
                password: null,
                interval: 30,
              ),
              onEnabledChanged: (value) => enabled = value,
              onRepeaterIdChanged: (_) {},
              onPasswordChanged: (_) {},
              onIntervalChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(DropdownButton<int>), findsNothing);
    await tester.tap(find.byType(SwitchListTile));

    expect(enabled, isTrue);
  });

  testWidgets('map display section delegates typed setting changes', (
    tester,
  ) async {
    MapDisplaySetting? changedSetting;
    bool? changedValue;
    await pumpWithL10n(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: ListView(
            children: buildMapDisplaySettings(
              context,
              values: const MapDisplaySettingsValues(
                showCoverage: false,
                mapLodEnabled: false,
                showSamples: false,
                showEdges: false,
                showRepeaters: false,
                showGpsSamples: false,
                showSuccessfulOnly: false,
                showRouteTrail: false,
                communityCoverageAvailable: false,
                showCommunityCoverage: false,
                showHeatmap: false,
                showPredictionRings: false,
              ),
              onChanged: (setting, value) {
                changedSetting = setting;
                changedValue = value;
              },
              onClearCommunityCoverage: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SwitchListTile).first);

    expect(changedSetting, MapDisplaySetting.coverage);
    expect(changedValue, isTrue);
  });
}
