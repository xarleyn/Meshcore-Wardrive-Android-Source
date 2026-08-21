import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/screens/map/dialogs/map_workflow_dialogs.dart';

import '../helpers/l10n_harness.dart';

void main() {
  testWidgets('sample export format dialog returns a typed format', (
    tester,
  ) async {
    SampleExportFormat? result;
    await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<SampleExportFormat>(
                context: context,
                builder: (context) => const SampleExportFormatDialog(),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GPX'));
    await tester.pumpAndSettle();

    expect(result, SampleExportFormat.gpx);
  });

  testWidgets('export destination dialog returns a typed destination', (
    tester,
  ) async {
    ExportDestination? result;
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<ExportDestination>(
                context: context,
                builder: (context) =>
                    const ExportDestinationDialog(title: 'Export'),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.mapShare));
    await tester.pumpAndSettle();

    expect(result, ExportDestination.share);
  });

  testWidgets('continue request dialog returns confirmation', (tester) async {
    bool? result;
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (context) => const ContinueRequestDialog(
                  title: 'Permission',
                  message: 'Needed for tracking',
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
    await tester.tap(find.text(l10n.mapContinue));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
