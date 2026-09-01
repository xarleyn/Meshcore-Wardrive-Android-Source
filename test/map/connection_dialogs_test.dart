import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/connection_dialogs.dart';

import '../helpers/l10n_harness.dart';

void main() {
  testWidgets('connection dialog returns a typed method', (tester) async {
    ConnectionMethod? result;
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<ConnectionMethod>(
                context: context,
                builder: (context) => const ConnectionMethodDialog(),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.mapScanBluetooth));
    await tester.pumpAndSettle();

    expect(result, ConnectionMethod.bluetooth);
  });
}
