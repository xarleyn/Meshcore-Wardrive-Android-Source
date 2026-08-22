import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

import '../../../l10n/generated/app_localizations.dart';

enum ConnectionMethod { usb, bluetooth }

class ConnectionMethodDialog extends StatelessWidget {
  const ConnectionMethodDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapConnectLoraDevice),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mapChooseConnectionMethod,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _methodButton(
            context,
            method: ConnectionMethod.usb,
            icon: Icons.usb,
            label: l10n.mapScanUsbDevices,
          ),
          const SizedBox(height: 8),
          _methodButton(
            context,
            method: ConnectionMethod.bluetooth,
            icon: Icons.bluetooth,
            label: l10n.mapScanBluetooth,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.mapClose),
        ),
      ],
    );
  }

  Widget _methodButton(
    BuildContext context, {
    required ConnectionMethod method,
    required IconData icon,
    required String label,
  }) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pop(context, method),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 40),
      ),
    );
  }
}

class UsbDeviceDialog extends StatelessWidget {
  const UsbDeviceDialog({required this.devices, super.key});

  final List<UsbDevice> devices;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapSelectUsbDevice),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final device in devices)
            ListTile(
              title: Text(device.productName ?? l10n.mapUsbDeviceFallback),
              subtitle: Text(l10n.mapVidPid('${device.vid}', '${device.pid}')),
              onTap: () => Navigator.pop(context, device),
            ),
        ],
      ),
    );
  }
}

class DisconnectDeviceDialog extends StatelessWidget {
  const DisconnectDeviceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.mapDisconnectLoraDevice),
      content: Text(l10n.mapDisconnectConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.settingsCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.mapDisconnect),
        ),
      ],
    );
  }
}
