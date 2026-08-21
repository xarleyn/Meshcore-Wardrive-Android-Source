import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/upload_endpoint_dialog.dart';
import 'package:meshcore_wardrive/services/upload_service.dart';

import '../helpers/l10n_harness.dart';

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

  testWidgets('community coverage dialog returns a typed endpoint', (
    tester,
  ) async {
    UploadEndpoint? result;
    const endpoint = UploadEndpoint(
      name: 'Community',
      url: 'https://community.example/api',
    );
    await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<UploadEndpoint>(
                context: context,
                builder: (context) => const CommunityCoverageEndpointDialog(
                  endpoints: [endpoint],
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();

    expect(result, same(endpoint));
  });

  testWidgets('upload progress starts once and returns typed results', (
    tester,
  ) async {
    UploadProgressOutcome? outcome;
    var starts = 0;
    await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              outcome = await showDialog<UploadProgressOutcome>(
                context: context,
                barrierDismissible: false,
                builder: (context) => UploadProgressDialog(
                  upload: (onProgress) async {
                    starts++;
                    onProgress('Community', 1, 2);
                    await Future<void>.delayed(Duration.zero);
                    onProgress('Community', 2, 2);
                    return {
                      'Community': UploadResult(
                        success: true,
                        message: 'Uploaded',
                      ),
                    };
                  },
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(starts, 1);
    expect(outcome?.error, isNull);
    expect(outcome?.results?['Community']?.success, isTrue);
  });

  testWidgets('upload sites sheet returns edits only when saved', (
    tester,
  ) async {
    UploadSitesConfiguration? configuration;
    const endpoint = UploadEndpoint(
      name: 'Community',
      url: 'https://community.example/api',
    );
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              configuration =
                  await showModalBottomSheet<UploadSitesConfiguration>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const ManageUploadSitesSheet(
                      initialEndpoints: [endpoint],
                      initiallySelectedNames: [],
                    ),
                  );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text(l10n.settingsSave));
    await tester.pumpAndSettle();

    expect(configuration?.endpoints, [endpoint]);
    expect(configuration?.selectedNames, ['Community']);
  });
}
