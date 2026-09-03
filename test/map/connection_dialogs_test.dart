import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/connection_dialogs.dart';

import '../helpers/pump_dialog.dart';

void main() {
  testWidgets('connection dialog returns a typed method', (tester) async {
    ConnectionMethod? result;
    final l10n = await pumpDialog(tester, (context) async {
      result = await showDialog<ConnectionMethod>(
        context: context,
        builder: (context) => const ConnectionMethodDialog(),
      );
    });

    await openDialog(tester);
    await tester.tap(find.text(l10n.mapScanBluetooth));
    await tester.pumpAndSettle();

    expect(result, ConnectionMethod.bluetooth);
  });
}
