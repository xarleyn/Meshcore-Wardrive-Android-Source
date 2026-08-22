import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/l10n/generated/app_localizations.dart';
import 'package:meshcore_wardrive/utils/bluetooth_scan.dart';
import 'package:meshcore_wardrive/widgets/bluetooth_device_picker_dialog.dart';

import '../helpers/l10n_harness.dart';

void main() {
  Future<AppLocalizations> showPicker(
    WidgetTester tester, {
    required Stream<BluetoothScanSnapshot> scan,
    ValueNotifier<BluetoothScanEntry?>? result,
  }) async {
    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              final selected = await showDialog<BluetoothScanEntry>(
                context: context,
                builder: (context) => BluetoothDevicePickerDialog(scan: scan),
              );
              result?.value = selected;
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    return l10n;
  }

  testWidgets('shows previously used devices while the scan is still running', (
    tester,
  ) async {
    final scan = StreamController<BluetoothScanSnapshot>.broadcast();
    addTearDown(scan.close);

    final l10n = await showPicker(tester, scan: scan.stream);
    scan.add(
      BluetoothScanSnapshot(
        devices: [
          BluetoothScanEntry(
            remoteId: 'AA:BB:CC:DD:EE:FF',
            name: 'MeshCore One',
            previouslyUsed: true,
          ),
        ],
        isScanning: true,
      ),
    );
    await tester.pump();

    expect(find.text(l10n.bluetoothSelectDevice), findsOneWidget);
    expect(find.text('MeshCore One'), findsOneWidget);
    expect(find.text(l10n.bluetoothPreviouslyUsed), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('appends newly discovered devices as the scan reports them', (
    tester,
  ) async {
    final scan = StreamController<BluetoothScanSnapshot>.broadcast();
    addTearDown(scan.close);

    final l10n = await showPicker(tester, scan: scan.stream);
    scan.add(
      const BluetoothScanSnapshot(
        devices: [
          BluetoothScanEntry(
            remoteId: 'AA:BB:CC:DD:EE:FF',
            name: 'MeshCore One',
            previouslyUsed: true,
          ),
        ],
        isScanning: true,
      ),
    );
    await tester.pump();
    scan.add(
      const BluetoothScanSnapshot(
        devices: [
          BluetoothScanEntry(
            remoteId: 'AA:BB:CC:DD:EE:FF',
            name: 'MeshCore One',
            previouslyUsed: true,
            currentlyVisible: true,
          ),
          BluetoothScanEntry(
            remoteId: '11:22:33:44:55:66',
            name: 'Heltec V3',
            currentlyVisible: true,
          ),
        ],
        isScanning: true,
      ),
    );
    await tester.pump();

    expect(find.text('MeshCore One'), findsOneWidget);
    expect(find.text('Heltec V3'), findsOneWidget);
    expect(find.text(l10n.bluetoothNearby), findsOneWidget);
  });

  testWidgets('returns the tapped device and hides the scanning indicator', (
    tester,
  ) async {
    final scan = StreamController<BluetoothScanSnapshot>.broadcast();
    addTearDown(scan.close);
    final result = ValueNotifier<BluetoothScanEntry?>(null);

    final l10n = await showPicker(tester, scan: scan.stream, result: result);
    scan.add(
      const BluetoothScanSnapshot(
        devices: [
          BluetoothScanEntry(
            remoteId: 'AA:BB:CC:DD:EE:FF',
            name: 'MeshCore One',
            previouslyUsed: true,
            currentlyVisible: true,
          ),
        ],
        isScanning: false,
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('MeshCore One'));
    await tester.pumpAndSettle();

    expect(result.value?.remoteId, 'AA:BB:CC:DD:EE:FF');
    expect(find.text(l10n.bluetoothSelectDevice), findsNothing);
  });
}
