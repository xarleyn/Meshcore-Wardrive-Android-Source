import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/appearance_dialogs.dart';
import 'package:meshcore_wardrive/services/settings_service.dart';

import '../helpers/l10n_harness.dart';

void main() {
  testWidgets('map theme dialog returns a typed theme', (tester) async {
    MapThemeMode? result;
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<MapThemeMode>(
                context: context,
                builder: (context) => const MapThemeDialog(),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsThemeDark));
    await tester.pumpAndSettle();

    expect(result, MapThemeMode.dark);
  });
}
