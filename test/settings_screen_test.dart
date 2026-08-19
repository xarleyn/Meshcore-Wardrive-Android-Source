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

  testWidgets('scrolls settings to the bottom and back to the top', (
    tester,
  ) async {
    final l10n = await pumpWithL10n(
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

    await tester.tap(find.byTooltip(l10n.settingsScrollToBottom));
    await tester.pumpAndSettle();

    expect(find.text('Setting 0'), findsNothing);
    expect(find.text('Setting 29'), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.settingsScrollToTop));
    await tester.pumpAndSettle();

    expect(find.text('Setting 0'), findsOneWidget);
    expect(find.text('Setting 29'), findsNothing);
  });
}
