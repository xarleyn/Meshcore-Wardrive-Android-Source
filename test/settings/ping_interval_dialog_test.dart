import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/settings/settings_dialogs.dart';
import 'package:meshcore_wardrive/screens/settings/sections/discovery_section.dart';
import 'package:meshcore_wardrive/screens/settings/settings_screen.dart';

import '../helpers/l10n_harness.dart';

void main() {
  testWidgets('ping distance dialog closes, applies value, keeps page open', (
    tester,
  ) async {
    double? selectedInterval;
    var pingIntervalMeters = 805.0;
    var categoryPageOpen = false;

    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (mapContext) => FilledButton(
            onPressed: () {
              // Mirrors _showSettings + _openSettingsCategory in
              // settings_page.dart: the edit callback captures the overview
              // page's BuildContext, not the category page's.
              Navigator.of(mapContext).push(
                MaterialPageRoute<void>(
                  builder: (context) => SettingsScreen(
                    version: '1.0.0',
                    contentBuilder: (overviewContext, overviewSetState, scrollController) {
                      return ListView(
                        controller: scrollController,
                        children: [
                          SettingsCategoryTile(
                            title: 'Discovery',
                            subtitle: 'Test',
                            icon: Icons.radar_outlined,
                            onTap: () => Navigator.of(overviewContext).push(
                              MaterialPageRoute<void>(
                                builder: (context) => SettingsScreen.category(
                                  title: 'Discovery',
                                  contentBuilder:
                                      (
                                        context,
                                        setPageState,
                                        scrollController,
                                      ) {
                                        categoryPageOpen = true;
                                        return ListView(
                                          controller: scrollController,
                                          children: [
                                            SettingsContentCard(
                                              children: buildDiscoverySettings(
                                                context,
                                                values: DiscoverySettingsValues(
                                                  timeoutSeconds: 10,
                                                  responseCollectionMode:
                                                      'fast',
                                                  ignoredRepeaterPrefix: null,
                                                  includeOnlyRepeaters: null,
                                                  filterEdgesByWhitelist: false,
                                                  pingMode: 'distance',
                                                  pingTimeInterval: 10,
                                                  pingIntervalDescription:
                                                      pingIntervalDescription(
                                                        context,
                                                        pingIntervalMeters,
                                                      ),
                                                  coverageResolutionDescription:
                                                      'Street',
                                                ),
                                                onTimeoutChanged: (_) {},
                                                onCollectionModeChanged: (_) {},
                                                onEditIgnoredRepeaters: () {},
                                                onEditIncludedRepeaters: () {},
                                                onFilterEdgesChanged: (_) {},
                                                onPingModeChanged: (_) {},
                                                onEditPingInterval: () async {
                                                  final interval =
                                                      await showPingIntervalDialog(
                                                        overviewContext,
                                                      );
                                                  if (interval == null) {
                                                    return;
                                                  }
                                                  // Mirrors the
                                                  // fixed
                                                  // _editPingInterval:
                                                  // apply, then
                                                  // refresh the
                                                  // category page.
                                                  selectedInterval = interval;
                                                  pingIntervalMeters = interval;
                                                  setPageState(() {});
                                                },
                                                onPingTimeIntervalChanged: (
                                                  _,
                                                ) {},
                                                onEditCoverageResolution: () {},
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
            child: const Text('Open settings'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discovery'));
    await tester.pumpAndSettle();

    // The category page starts at the sparse default description.
    expect(find.text(l10n.settingsPingIntervalMeters(805)), findsOneWidget);

    // Open the "Ping Distance" (Расстояние пинга) editor dialog.
    await tester.tap(find.text(l10n.settingsPingDistance));
    await tester.pumpAndSettle();

    // The dialog title matches the settings tile label.
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.settingsPingDistance),
      ),
      findsOneWidget,
    );

    // Select the "Frequent" (50 m) option.
    await tester.tap(find.text(l10n.settingsPingFrequent));
    await tester.pumpAndSettle();

    // The dialog closes itself, returns the chosen double value...
    expect(selectedInterval, 50.0);
    expect(find.byType(AlertDialog), findsNothing);
    // ...the settings category page stays open...
    expect(categoryPageOpen, isTrue);
    expect(find.text(l10n.settingsPingDistance), findsOneWidget);
    // ...and its subtitle refreshes to the new value.
    expect(
      find.text(l10n.settingsPingIntervalMetersFrequent(50)),
      findsOneWidget,
    );
  });

  testWidgets('coverage resolution dialog returns the selected precision', (
    tester,
  ) async {
    int? selectedPrecision;

    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              selectedPrecision = await showCoverageResolutionDialog(context);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsCoverageStreet));
    await tester.pumpAndSettle();

    expect(selectedPrecision, 7);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
