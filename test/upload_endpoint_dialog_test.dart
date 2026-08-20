import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/upload_endpoint_dialog.dart';
import 'package:meshcore_wardrive/services/upload_service.dart';

import 'helpers/l10n_harness.dart';

void main() {
  testWidgets('edits and returns a typed upload endpoint', (tester) async {
    UploadEndpoint? result;
    const existing = UploadEndpoint(
      name: 'Old name',
      url: 'https://old.example/api',
    );
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<UploadEndpoint>(
                context: context,
                builder: (context) =>
                    const UploadEndpointDialog(existing: existing),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'New name');
    await tester.enterText(
      find.byType(TextField).last,
      'https://new.example/api',
    );
    await tester.tap(find.text(l10n.settingsSave));
    await tester.pumpAndSettle();

    expect(result?.name, 'New name');
    expect(result?.url, 'https://new.example/api');
  });
}
