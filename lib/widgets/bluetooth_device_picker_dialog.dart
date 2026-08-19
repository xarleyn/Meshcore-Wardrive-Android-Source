import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final devices = _snapshot.devices;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(l10n.bluetoothSelectDevice)),
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
              ? Text(_emptyMessage(l10n))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final statusLabel = _statusLabel(l10n, device);
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
                          if (statusLabel != null) Text(statusLabel),
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
          child: Text(l10n.bluetoothCancel),
        ),
      ],
    );
  }

  String _emptyMessage(AppLocalizations l10n) {
    final error = _snapshot.error;
    if (error != null) return l10n.bluetoothError(error);
    if (_snapshot.isScanning) return l10n.bluetoothSearching;
    return l10n.bluetoothNoDevices;
  }

  String? _statusLabel(AppLocalizations l10n, BluetoothScanEntry device) {
    if (device.previouslyUsed) return l10n.bluetoothPreviouslyUsed;
    if (device.currentlyVisible) return l10n.bluetoothNearby;
    return null;
  }
}
