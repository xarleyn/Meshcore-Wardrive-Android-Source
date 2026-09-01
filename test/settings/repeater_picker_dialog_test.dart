import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_wardrive/l10n/generated/app_localizations.dart';
import 'package:meshcore_wardrive/models/models.dart';
import 'package:meshcore_wardrive/screens/settings/widgets/repeater_picker_dialog.dart';

import '../helpers/l10n_harness.dart';

void main() {
  final alpha = Repeater(
    id: 'ABC12345',
    position: const LatLng(55.1, 32.2),
    name: 'alpha',
  );
  final bravo = Repeater(
    id: 'BAD5DC49',
    position: const LatLng(55.2, 32.3),
    name: 'Bravo',
  );
  final unnamed = Repeater(id: 'DEADBEEF', position: const LatLng(0, 0));

  testWidgets('rows show name together with ID, sorted by name', (
    tester,
  ) async {
    await _pumpPicker(tester, repeaters: [bravo, unnamed, alpha]);

    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title as Text?)?.data)
        .toList();
    expect(titles, ['alpha', 'Bravo', 'DEADBEEF']);
    expect(find.text('ABC12345'), findsOneWidget);
    expect(find.text('BAD5DC49'), findsOneWidget);
  });

  testWidgets('search filters by ID and by name case-insensitively', (
    tester,
  ) async {
    final l10n = await _pumpPicker(tester, repeaters: [alpha, bravo]);

    await tester.enterText(find.byType(TextField), 'bad5');
    await tester.pump();
    expect(find.text('Bravo'), findsOneWidget);
    expect(find.text('alpha'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ALPHA');
    await tester.pump();
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('Bravo'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text(l10n.mapNoRepeatersFound), findsOneWidget);
  });

  testWidgets('tapping a row selects its uppercase ID', (tester) async {
    final (result, _) = await _openPicker(
      tester,
      repeaters: [alpha, bravo],
      act: (l10n) => tester.tap(find.text('Bravo')),
    );
    expect(result?.action, RepeaterPickAction.select);
    expect(result?.repeaterId, 'BAD5DC49');
  });
  testWidgets('selected repeater is highlighted', (tester) async {
    await _pumpPicker(tester, repeaters: [alpha], selectedId: 'abc12345');

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('clear action is hidden when nothing is selected', (
    tester,
  ) async {
    final l10n = await _pumpPicker(
      tester,
      repeaters: [alpha],
      selectedId: null,
    );
    expect(find.widgetWithText(TextButton, l10n.settingsClear), findsNothing);
  });

  testWidgets('clear action is offered when something is selected', (
    tester,
  ) async {
    final l10n = await _pumpPicker(
      tester,
      repeaters: [alpha],
      selectedId: 'ABC12345',
    );
    expect(find.widgetWithText(TextButton, l10n.settingsClear), findsOneWidget);
  });

  testWidgets('manual entry action returns manualEntry result', (tester) async {
    final (result, l10n) = await _openPicker(
      tester,
      repeaters: const [],
      act: (l10n) => tester.tap(find.text(l10n.settingsEnterRepeaterManually)),
    );
    expect(result?.action, RepeaterPickAction.manualEntry);
  });
}

Future<AppLocalizations> _pumpPicker(
  WidgetTester tester, {
  required List<Repeater> repeaters,
  String? selectedId,
}) async {
  final l10n = await pumpWithL10n(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showRepeaterPickerDialog(
              context: context,
              repeaters: repeaters,
              selectedId: selectedId,
            ),
            child: const Text('open picker'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open picker'));
  await tester.pumpAndSettle();
  return l10n;
}

/// Opens the picker through [showRepeaterPickerDialog] like production code,
/// runs [act] against the visible dialog, and returns the popped result.
Future<(RepeaterPickResult?, AppLocalizations)> _openPicker(
  WidgetTester tester, {
  required List<Repeater> repeaters,
  required Future<void> Function(AppLocalizations l10n) act,
}) async {
  final completer = Completer<RepeaterPickResult?>();
  final l10n = await pumpWithL10n(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showRepeaterPickerDialog(
            context: context,
            repeaters: repeaters,
          ).then(completer.complete),
          child: const Text('open picker'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open picker'));
  await tester.pumpAndSettle();
  await act(l10n);
  final result = await completer.future;
  return (result, l10n);
}
