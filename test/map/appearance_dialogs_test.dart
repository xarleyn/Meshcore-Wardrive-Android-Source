import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/appearance_dialogs.dart';
import 'package:meshcore_wardrive/services/settings_service.dart';

import '../helpers/pump_dialog.dart';

void main() {
  testWidgets('map theme dialog returns a typed theme', (tester) async {
    MapThemeMode? result;
    final l10n = await pumpDialog(tester, (context) async {
      result = await showDialog<MapThemeMode>(
        context: context,
        builder: (context) => const MapThemeDialog(),
      );
    });

    await openDialog(tester);
    await tester.tap(find.text(l10n.settingsThemeDark));
    await tester.pumpAndSettle();

    expect(result, MapThemeMode.dark);
  });
}
