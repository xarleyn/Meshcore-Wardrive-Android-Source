import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:usb_serial/usb_serial.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/settings_service.dart';
import '../../utils/bluetooth_scan.dart';
import '../../widgets/bluetooth_device_picker_dialog.dart';
import 'dialogs/connection_dialogs.dart';

/// Companion radio connection orchestration for the map screen.
///
/// The flow owns no state: it drives the USB/Bluetooth connection dialogs and
/// the LoRa companion service through the injected [locationService], and
/// delegates everything that belongs to the screen (snackbars, the connecting
/// flag, list updates, and reloads) to callbacks. Localization, dialogs, and
/// mounted checks resolve against the owning screen's [context].
class ConnectionFlow {
  const ConnectionFlow({
    required this.context,
    required this.onShowSnackBar,
    required this.locationService,
    required this.settingsService,
    required this.databaseService,
    required this.isConnecting,
    required this.setConnecting,
    required this.loraConnected,
    required this.onLoadSamples,
    required this.onDeviceDisconnected,
    required this.onRepeatersReplaced,
    required this.onRepeatersFound,
  });

  /// Screen context used for mounted checks, localization, and dialogs.
  final BuildContext context;

  /// Shows a transient message; the owner guards this callback with its own
  /// mounted check.
  final void Function(String message) onShowSnackBar;

  final LocationService locationService;
  final SettingsService settingsService;
  final DatabaseService databaseService;

  /// Current connecting flag; concurrent connections are refused while true.
  final bool Function() isConnecting;

  /// Toggles the connecting flag on the screen (wrapped in setState).
  final void Function(bool connecting) setConnecting;

  /// Whether a LoRa companion is currently connected.
  final bool Function() loraConnected;

  /// Reloads samples after a successful connection or disconnect.
  final Future<void> Function() onLoadSamples;

  /// Applies screen state updates after the device was disconnected.
  final VoidCallback onDeviceDisconnected;

  /// Applies scanned repeaters to the screen data (wrapped in setState).
  final void Function(List<Repeater> repeaters) onRepeatersReplaced;

  /// Opens the repeater list after a successful scan.
  final Future<void> Function() onRepeatersFound;

  /// Asks for the connection method and runs the matching connection flow.
  Future<void> showConnectionDialog() async {
    final method = await showDialog<ConnectionMethod>(
      context: context,
      builder: (dialogContext) => const ConnectionMethodDialog(),
    );
    switch (method) {
      case ConnectionMethod.usb:
        await connectUsb();
      case ConnectionMethod.bluetooth:
        await connectBluetooth();
      case null:
        return;
    }
  }

  /// Scans for USB companions and connects to the selected one.
  Future<void> connectUsb() async {
    if (isConnecting()) return;
    setConnecting(true);
    try {
      final devices = await locationService.loraCompanion.scanUsbDevices();

      if (!context.mounted) return;

      if (devices.isEmpty) {
        onShowSnackBar(AppLocalizations.of(context).mapNoUsbDevices);
        return;
      }

      final selected = await showDialog<UsbDevice>(
        context: context,
        builder: (dialogContext) => UsbDeviceDialog(devices: devices),
      );

      if (selected != null) {
        final connected = await locationService.loraCompanion.connectUsb(
          selected,
        );
        if (connected) {
          if (!context.mounted) return;
          onShowSnackBar(AppLocalizations.of(context).mapConnectedViaUsb);
          await onLoadSamples();
        } else {
          if (!context.mounted) return;
          onShowSnackBar(AppLocalizations.of(context).mapFailedConnectUsb);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapUsbError('$e'));
    } finally {
      if (context.mounted) setConnecting(false);
    }
  }

  /// Offers recent, tracked, and bonded Bluetooth companions and connects to
  /// the selected one, remembering the choice on success.
  Future<void> connectBluetooth() async {
    if (isConnecting()) return;
    setConnecting(true);
    try {
      final recent = await settingsService.getRecentBluetoothDevices();
      final tracked = [
        for (final row in await databaseService.getAllDevices())
          if (row['connection_type'] == 'bluetooth')
            KnownBluetoothDevice(
              remoteId:
                  bluetoothRemoteIdFromStoredId('${row['public_key'] ?? ''}') ??
                  '',
              name: '${row['name'] ?? ''}',
            ),
      ].where((device) => device.remoteId.isNotEmpty).toList();
      final bonded = await locationService.loraCompanion
          .getBondedCompanionDevices();
      final known = collectKnownBluetoothDevices(
        recent: recent,
        tracked: tracked,
        bonded: bonded,
      );

      if (!context.mounted) return;
      final selected = await showDialog<BluetoothScanEntry>(
        context: context,
        builder: (dialogContext) => BluetoothDevicePickerDialog(
          scan: locationService.loraCompanion.watchBluetoothScan(
            knownDevices: known,
          ),
        ),
      );

      if (selected == null) return;

      if (!context.mounted) return;
      onShowSnackBar(
        AppLocalizations.of(context).mapConnectingTo(selected.displayName),
      );

      final connected = await locationService.loraCompanion.connectBluetooth(
        BluetoothDevice.fromId(selected.remoteId),
      );
      if (connected) {
        await settingsService.rememberBluetoothDevice(
          remoteId: selected.remoteId,
          name: locationService.loraCompanion.deviceName ?? selected.name,
        );
        if (!context.mounted) return;
        onShowSnackBar(AppLocalizations.of(context).mapConnectedViaBluetooth);
        await onLoadSamples();
      } else {
        if (!context.mounted) return;
        onShowSnackBar(AppLocalizations.of(context).mapFailedConnectBluetooth);
      }
    } catch (e) {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).bluetoothError('$e'));
    } finally {
      if (context.mounted) setConnecting(false);
    }
  }

  /// Disconnects the companion after confirmation and stops auto-ping and
  /// Carpeater.
  Future<void> disconnectLoRa() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const DisconnectDeviceDialog(),
    );

    if (confirmed == true) {
      // Disable auto-ping and carpeater
      locationService.disableAutoPing();
      locationService.carpeaterService.stop();
      onDeviceDisconnected();

      await locationService.loraCompanion.disconnectDevice();
      await onLoadSamples();
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapLoraDisconnected);
    }
  }

  /// Refreshes the companion contact list, waiting for it to process.
  Future<void> refreshContacts() async {
    if (!loraConnected()) {
      onShowSnackBar(AppLocalizations.of(context).mapConnectLoraFirst);
      return;
    }

    onShowSnackBar(AppLocalizations.of(context).mapRefreshingContactList);

    // Request full contact list from device
    await locationService.loraCompanion.refreshContactList();

    // Give it a moment to process
    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;
    onShowSnackBar(AppLocalizations.of(context).mapContactListUpdated);
  }

  /// Scans for repeaters, replaces the screen's repeater list with the result
  /// and opens it.
  Future<void> scanForRepeaters() async {
    if (!loraConnected()) {
      onShowSnackBar(AppLocalizations.of(context).mapConnectLoraFirst);
      return;
    }

    onShowSnackBar(AppLocalizations.of(context).mapScanningForRepeaters);

    final repeaters = await locationService.loraCompanion.scanForRepeaters();

    onRepeatersReplaced(repeaters);

    if (repeaters.isEmpty) {
      if (!context.mounted) return;
      onShowSnackBar(AppLocalizations.of(context).mapNoRepeatersFound);
    } else {
      if (!context.mounted) return;
      onShowSnackBar(
        AppLocalizations.of(context).mapRepeatersFound(repeaters.length),
      );
      await onRepeatersFound();
    }
  }
}
