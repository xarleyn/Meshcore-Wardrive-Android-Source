import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/l10n/generated/app_localizations.dart';
import 'package:meshcore_wardrive/screens/settings/settings_screen.dart';
import 'package:meshcore_wardrive/services/upload_service.dart';

import '../helpers/l10n_harness.dart';

void main() {
  const firstEndpoint = UploadEndpoint(
    name: 'First site',
    url: 'https://first.example/upload',
  );
  const secondEndpoint = UploadEndpoint(
    name: 'Second site',
    url: 'https://second.example/upload',
  );

  Future<AppLocalizations> showSelectionDialog(
    WidgetTester tester,
    ValueNotifier<List<String>?> result,
  ) async {
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result.value = await showDialog<List<String>>(
                context: context,
                builder: (context) => const UploadEndpointSelectionDialog(
                  endpoints: [firstEndpoint, secondEndpoint],
                  initiallySelectedNames: ['First site'],
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
    return l10n;
  }

  testWidgets('returns all sites selected for upload', (tester) async {
    final result = ValueNotifier<List<String>?>(null);
    final l10n = await showSelectionDialog(tester, result);

    expect(find.text(l10n.settingsUploadData), findsOneWidget);
    expect(find.text(l10n.settingsUploadSelectSites), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('upload-endpoint-First site')),
          )
          .value,
      isTrue,
    );

    await tester.tap(find.text('Second site'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, l10n.settingsUpload));
    await tester.pumpAndSettle();

    expect(result.value, ['First site', 'Second site']);
  });

  testWidgets('cancel closes the dialog without submitting', (tester) async {
    final result = ValueNotifier<List<String>?>(null);
    final l10n = await showSelectionDialog(tester, result);

    await tester.tap(find.widgetWithText(TextButton, l10n.settingsCancel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsUploadData), findsNothing);
    expect(result.value, isNull);
  });

  testWidgets('upload is disabled when no site is selected', (tester) async {
    final result = ValueNotifier<List<String>?>(null);
    await showSelectionDialog(tester, result);

    await tester.tap(find.text('First site'));
    await tester.pump();

    final uploadButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('upload-endpoint-submit')),
    );
    expect(uploadButton.onPressed, isNull);
  });
}
