import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/settings/settings_screen.dart';

void main() {
  testWidgets('renders settings as a full categorized page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          version: '1.2.3',
          contentBuilder: (context, setPageState, scrollController) {
            return ListView(
              controller: scrollController,
              children: const [
                SettingsSectionHeader(
                  title: 'Map display',
                  icon: Icons.map_outlined,
                ),
                ListTile(title: Text('Show Coverage Boxes')),
              ],
            );
          },
        ),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('v1.2.3'), findsOneWidget);
    expect(find.text('Map display'), findsOneWidget);
    expect(find.text('Show Coverage Boxes'), findsOneWidget);
  });

  testWidgets('keeps text controller alive through dialog dismissal', (
    tester,
  ) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showSettingsTextInputDialog(
                  context: context,
                  title: 'Maximum Horizontal Error',
                  initialValue: '250',
                  labelText: 'Maximum Horizontal Error',
                  suffixText: 'm',
                );
              },
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '300');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(result, '300');
  });
}
