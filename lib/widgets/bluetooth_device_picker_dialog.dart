import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/bluetooth_scan.dart';

class BluetoothDevicePickerDialog extends StatefulWidget {
  const BluetoothDevicePickerDialog({required this.scan, super.key});

  final Stream<BluetoothScanSnapshot> scan;

  @override
  State<BluetoothDevicePickerDialog> createState() =>
      _BluetoothDevicePickerDialogState();
}

class _BluetoothDevicePickerDialogState
    extends State<BluetoothDevicePickerDialog> {
  StreamSubscription<BluetoothScanSnapshot>? _subscription;
  BluetoothScanSnapshot _snapshot = const BluetoothScanSnapshot(
    devices: [],
    isScanning: true,
  );

  @override
  void initState() {
    super.initState();
    _subscription = widget.scan.listen((snapshot) {
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = _snapshot.devices;
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Select Bluetooth Device')),
          if (_snapshot.isScanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: devices.isEmpty
              ? Text(_emptyMessage)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        device.previouslyUsed
                            ? Icons.history
                            : Icons.bluetooth_searching,
                      ),
                      title: Text(device.displayName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (device.statusLabel.isNotEmpty)
                            Text(device.statusLabel),
                          Text(device.remoteId),
                        ],
                      ),
                      onTap: () => Navigator.pop(context, device),
                    );
                  },
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String get _emptyMessage {
    if (_snapshot.error != null) return 'Bluetooth error: ${_snapshot.error}';
    if (_snapshot.isScanning) return 'Searching for LoRa devices...';
    return 'No LoRa devices found via Bluetooth';
  }
}
