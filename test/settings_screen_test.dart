import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/l10n/generated/app_localizations.dart';
import 'package:meshcore_wardrive/screens/settings/settings_screen.dart';

import 'helpers/l10n_harness.dart';

void main() {
  testWidgets('renders settings as a full categorized page', (tester) async {
    final l10n = await pumpWithL10n(
      tester,
      SettingsScreen(
        version: '1.2.3',
        contentBuilder: (context, setPageState, scrollController) {
          final l10n = AppLocalizations.of(context);
          return ListView(
            controller: scrollController,
            children: [
              SettingsSectionHeader(
                title: l10n.settingsSectionMapDisplay,
                icon: Icons.map_outlined,
              ),
              ListTile(title: Text(l10n.settingsShowCoverageBoxes)),
            ],
          );
        },
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text(l10n.settingsTitle), findsOneWidget);
    expect(find.text('v1.2.3'), findsOneWidget);
    expect(find.text(l10n.settingsSectionMapDisplay), findsOneWidget);
    expect(find.text(l10n.settingsShowCoverageBoxes), findsOneWidget);
  });

  testWidgets('shows a Russian settings title', (tester) async {
    final l10n = await pumpWithL10n(
      tester,
      SettingsScreen(
        version: '1.2.3',
        contentBuilder: (context, setPageState, scrollController) {
          return ListView(controller: scrollController);
        },
      ),
      locale: const Locale('ru'),
    );

    expect(find.text(l10n.settingsTitle), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
  });

  testWidgets('keeps text controller alive through dialog dismissal', (
    tester,
  ) async {
    String? result;

    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return FilledButton(
              onPressed: () async {
                result = await showSettingsTextInputDialog(
                  context: context,
                  title: l10n.settingsMaxHorizontalError,
                  initialValue: '250',
                  labelText: l10n.settingsMaxHorizontalError,
                  suffixText: 'm',
                );
              },
              child: const Text('Edit'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '300');
    await tester.tap(find.text(l10n.settingsSave));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(result, '300');
  });

  testWidgets('renders a dedicated settings category page', (tester) async {
    final l10n = await pumpWithL10n(
      tester,
      SettingsScreen.category(
        title: 'Location Quality Filters',
        contentBuilder: (context, setPageState, scrollController) {
          final l10n = AppLocalizations.of(context);
          return ListView(
            controller: scrollController,
            children: [ListTile(title: Text(l10n.settingsMaxHorizontalError))],
          );
        },
      ),
    );

    expect(find.text('Location Quality Filters'), findsOneWidget);
    expect(find.text(l10n.settingsMaxHorizontalError), findsOneWidget);
    expect(find.textContaining(RegExp(r'^v\d')), findsNothing);
  });

  testWidgets('opens a category from a modern settings overview card', (
    tester,
  ) async {
    await pumpWithL10n(
      tester,
      SettingsScreen(
        version: '1.2.3',
        contentBuilder: (context, setPageState, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            SettingsOverviewCard(
              children: [
                SettingsCategoryTile(
                  title: 'Map display',
                  icon: Icons.map_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => SettingsScreen.category(
                          title: 'Map display',
                          contentBuilder:
                              (context, setPageState, scrollController) =>
                                  ListView(
                                    controller: scrollController,
                                    padding: const EdgeInsets.all(16),
                                    children: const [
                                      SettingsContentCard(
                                        children: [
                                          ListTile(title: Text('Show cells')),
                                        ],
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );

    expect(find.byType(SettingsOverviewCard), findsOneWidget);
    expect(find.text('Map display'), findsOneWidget);

    await tester.tap(find.text('Map display'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsContentCard), findsOneWidget);
    expect(find.text('Show cells'), findsOneWidget);
  });

  testWidgets('supports standard scrolling on long category pages', (
    tester,
  ) async {
    await pumpWithL10n(
      tester,
      SettingsScreen.category(
        title: 'Long settings',
        contentBuilder: (context, setPageState, scrollController) => ListView(
          controller: scrollController,
          children: List.generate(
            30,
            (index) => ListTile(title: Text('Setting $index')),
          ),
        ),
      ),
    );

    expect(find.text('Setting 0'), findsOneWidget);
    expect(find.text('Setting 29'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.text('Setting 0'), findsNothing);
    expect(find.text('Setting 29'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();

    expect(find.text('Setting 0'), findsOneWidget);
    expect(find.text('Setting 29'), findsNothing);
  });
}
