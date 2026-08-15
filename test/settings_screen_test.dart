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
}
