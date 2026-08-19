import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/utils/bluetooth_scan.dart';
import 'package:meshcore_wardrive/widgets/bluetooth_device_picker_dialog.dart';

void main() {
  Future<void> showPicker(
    WidgetTester tester, {
    required Stream<BluetoothScanSnapshot> scan,
    ValueNotifier<BluetoothScanEntry?>? result,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
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
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
  }

  testWidgets('shows previously used devices while the scan is still running', (
    tester,
  ) async {
    final scan = StreamController<BluetoothScanSnapshot>.broadcast();
    addTearDown(scan.close);

    await showPicker(tester, scan: scan.stream);
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

    expect(find.text('Select Bluetooth Device'), findsOneWidget);
    expect(find.text('MeshCore One'), findsOneWidget);
    expect(find.text('Previously used'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('appends newly discovered devices as the scan reports them', (
    tester,
  ) async {
    final scan = StreamController<BluetoothScanSnapshot>.broadcast();
    addTearDown(scan.close);

    await showPicker(tester, scan: scan.stream);
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
    expect(find.text('Nearby'), findsOneWidget);
  });

  testWidgets('returns the tapped device and hides the scanning indicator', (
    tester,
  ) async {
    final scan = StreamController<BluetoothScanSnapshot>.broadcast();
    addTearDown(scan.close);
    final result = ValueNotifier<BluetoothScanEntry?>(null);

    await showPicker(tester, scan: scan.stream, result: result);
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
    expect(find.text('Select Bluetooth Device'), findsNothing);
  });
}
