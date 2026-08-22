import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/l10n/generated/app_localizations.dart';
import 'package:meshcore_wardrive/models/location_quality_settings.dart';
import 'package:meshcore_wardrive/screens/settings/sections/carpeater_section.dart';
import 'package:meshcore_wardrive/screens/settings/sections/feedback_section.dart';
import 'package:meshcore_wardrive/screens/settings/sections/location_quality_section.dart';
import 'package:meshcore_wardrive/screens/settings/sections/map_display_section.dart';

import '../helpers/l10n_harness.dart';

void main() {
  setUp(() => currentSettings = null);

  testWidgets('feedback section delegates switch changes', (tester) async {
    bool? soundEnabled;
    bool? linkLossAlertsEnabled;
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
                linkLossAlertsEnabled: false,
              ),
              onSoundChanged: (value) => soundEnabled = value,
              onVibrationChanged: (_) {},
              onDeadZoneAlertsChanged: (_) {},
              onNewRepeaterAlertsChanged: (_) {},
              onLinkLossAlertsChanged: (value) => linkLossAlertsEnabled = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.tap(find.byType(SwitchListTile).last);

    expect(soundEnabled, isTrue);
    expect(linkLossAlertsEnabled, isTrue);
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

  testWidgets('ping pause toggle hides the bad-fix threshold when off', (
    tester,
  ) async {
    final l10n = await _pumpLocationQualitySection(tester);

    await tester.tap(find.text('open location quality'));
    await tester.pumpAndSettle();

    // The threshold tile only exists while the pause feature is enabled.
    expect(find.text(l10n.settingsPingPauseOnBadFixes), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(currentSettings?.pausePingsOnBadFixes, isFalse);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(currentSettings?.pausePingsOnBadFixes, isTrue);

    final thresholdTitle = find.text(l10n.settingsPingPauseBadFixCount);
    await tester.scrollUntilVisible(thresholdTitle, 100);
    expect(thresholdTitle, findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('bad-fix threshold dialog validates and saves an integer', (
    tester,
  ) async {
    final l10n = await _pumpLocationQualitySection(tester);

    await tester.tap(find.text('open location quality'));
    await tester.pumpAndSettle();

    final thresholdTitle = find.text(l10n.settingsPingPauseBadFixCount);
    await tester.scrollUntilVisible(thresholdTitle, 100);
    await tester.tap(thresholdTitle);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text(l10n.settingsSave));
    await tester.pumpAndSettle();

    // Invalid input keeps the dialog open with the range error.
    expect(find.text(l10n.settingsEnterBadFixCount(1, 100)), findsOneWidget);
    expect(currentSettings, isNull);

    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text(l10n.settingsSave));
    await tester.pumpAndSettle();

    expect(currentSettings?.pingPauseBadFixCount, 12);
    expect(find.text('12'), findsOneWidget);
  });
}

LocationQualitySettings? currentSettings;

Future<AppLocalizations> _pumpLocationQualitySection(WidgetTester tester) {
  return pumpWithL10n(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showLocationQualitySettings(
              context,
              settings: () =>
                  currentSettings ?? const LocationQualitySettings(),
              zones: () => const [],
              newZoneCenter: () => const LatLng(55, 32),
              onSettingsChanged: (value) async => currentSettings = value,
              onResetSettings: () async {},
              onAddZone: (_) async {},
              onDeleteZone: (_) async {},
              onClearZones: () async {},
            ),
            child: const Text('open location quality'),
          ),
        ),
      ),
    ),
  );
}
