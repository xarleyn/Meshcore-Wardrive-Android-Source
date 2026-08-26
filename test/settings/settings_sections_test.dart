import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/l10n/generated/app_localizations.dart';
import 'package:meshcore_wardrive/models/location_quality_settings.dart';
import 'package:meshcore_wardrive/models/models.dart';
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

  testWidgets('carpeater target tile shows name and ID of the selection', (
    tester,
  ) async {
    await _pumpCarpeaterSection(
      tester,
      repeaterId: 'BAD5DC49',
      repeaters: [
        Repeater(
          id: 'BAD5DC49',
          position: const LatLng(55.1, 32.2),
          name: 'Hilltop',
        ),
      ],
    );

    expect(find.text('Hilltop'), findsOneWidget);
    expect(find.text('BAD5DC49'), findsOneWidget);
  });

  testWidgets('carpeater target tile opens searchable picker and delegates', (
    tester,
  ) async {
    String? pickedId;
    final l10n = await _pumpCarpeaterSection(
      tester,
      repeaters: [
        Repeater(
          id: 'BAD5DC49',
          position: const LatLng(55.1, 32.2),
          name: 'Hilltop',
        ),
      ],
      onRepeaterIdChanged: (value) => pickedId = value,
    );

    // Open the picker from the target repeater tile (the switch tile also
    // contains a ListTile, so match the title instead of the tile type).
    await tester.tap(find.text(l10n.settingsTargetRepeater));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsTargetRepeaterSearchHint), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Hilltop'),
      ),
    );
    await tester.pumpAndSettle();

    expect(pickedId, 'BAD5DC49');
  });

  testWidgets('map display section delegates typed setting changes', (
    tester,
  ) async {
    MapDisplaySetting? changedSetting;
    bool? changedValue;
    final l10n = await pumpWithL10n(
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
                sampleGeohashGrouping: false,
                showEdges: false,
                showRepeaters: false,
                showGpsSamples: false,
                showSuccessfulOnly: false,
                optimisticDisplay: false,
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

    // The optimistic coverage toggle reports its own setting kind.
    changedSetting = null;
    changedValue = null;
    final optimisticToggle = find.text(l10n.settingsOptimisticDisplay);
    await tester.scrollUntilVisible(optimisticToggle, 100);
    await tester.tap(optimisticToggle);

    expect(changedSetting, MapDisplaySetting.optimisticDisplay);
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

Future<AppLocalizations> _pumpCarpeaterSection(
  WidgetTester tester, {
  String? repeaterId,
  List<Repeater> repeaters = const [],
  void Function(String? value)? onRepeaterIdChanged,
}) {
  return pumpWithL10n(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: ListView(
          children: buildCarpeaterSettings(
            context,
            values: CarpeaterSettingsValues(
              enabled: true,
              repeaterId: repeaterId,
              password: null,
              interval: 30,
              foundRepeaters: repeaters,
            ),
            onEnabledChanged: (_) {},
            onRepeaterIdChanged: onRepeaterIdChanged ?? (_) {},
            onPasswordChanged: (_) {},
            onIntervalChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}

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
