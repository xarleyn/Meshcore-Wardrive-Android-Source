import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/utils/bluetooth_scan.dart';

void main() {
  group('isLikelyLoRaCompanion', () {
    test('matches known LoRa device names', () {
      expect(isLikelyLoRaCompanion(name: 'MeshCore T1000'), isTrue);
      expect(isLikelyLoRaCompanion(name: 'Heltec V3'), isTrue);
      expect(isLikelyLoRaCompanion(name: 'T-Beam Supreme'), isTrue);
      expect(isLikelyLoRaCompanion(name: 'WhisperOS node'), isTrue);
      expect(isLikelyLoRaCompanion(name: 'Meshtastic_ab12'), isTrue);
    });

    test('rejects unrelated names without extra signals', () {
      expect(isLikelyLoRaCompanion(name: 'WH-1000XM4'), isFalse);
      expect(isLikelyLoRaCompanion(name: ''), isFalse);
    });

    test('accepts a previously used device even with an empty name', () {
      expect(
        isLikelyLoRaCompanion(
          name: '',
          remoteId: 'AA:BB:CC:DD:EE:FF',
          knownRemoteIds: {'aabbccddeeff'},
        ),
        isTrue,
      );
    });

    test('accepts devices advertising the MeshCore UART service', () {
      expect(
        isLikelyLoRaCompanion(
          name: '',
          serviceUuids: const [meshCoreNordicUartServiceUuid],
        ),
        isTrue,
      );
    });
  });

  group('bluetoothRemoteIdFromStoredId', () {
    test('formats a 12-character MAC from the devices table', () {
      expect(
        bluetoothRemoteIdFromStoredId('AABBCCDDEEFF'),
        'AA:BB:CC:DD:EE:FF',
      );
    });

    test('keeps an already colon-separated identifier', () {
      expect(
        bluetoothRemoteIdFromStoredId('aa:bb:cc:dd:ee:ff'),
        'AA:BB:CC:DD:EE:FF',
      );
    });

    test('ignores USB device ids', () {
      expect(bluetoothRemoteIdFromStoredId('USB_Heltec'), isNull);
    });
  });

  group('collectKnownBluetoothDevices', () {
    test('keeps recent devices first and fills missing names later', () {
      final collected = collectKnownBluetoothDevices(
        recent: const [
          KnownBluetoothDevice(remoteId: 'AA:BB:CC:DD:EE:FF', name: ''),
        ],
        tracked: const [
          KnownBluetoothDevice(
            remoteId: 'aa:bb:cc:dd:ee:ff',
            name: 'MeshCore One',
          ),
          KnownBluetoothDevice(
            remoteId: '11:22:33:44:55:66',
            name: 'Heltec V3',
          ),
        ],
        bonded: const [
          KnownBluetoothDevice(
            remoteId: '11:22:33:44:55:66',
            name: 'Heltec V3',
          ),
          KnownBluetoothDevice(remoteId: 'DE:AD:BE:EF:00:01', name: 'T-Beam'),
        ],
      );

      expect(collected.map((device) => device.remoteId), [
        'AA:BB:CC:DD:EE:FF',
        '11:22:33:44:55:66',
        'DE:AD:BE:EF:00:01',
      ]);
      expect(collected.first.name, 'MeshCore One');
    });
  });

  group('mergeBluetoothScanResults', () {
    test('shows known devices before newly discovered ones', () {
      final merged = mergeBluetoothScanResults(
        known: const [
          KnownBluetoothDevice(
            remoteId: 'AA:BB:CC:DD:EE:FF',
            name: 'MeshCore One',
          ),
        ],
        discovered: const [
          DiscoveredBluetoothDevice(
            remoteId: '11:22:33:44:55:66',
            name: 'Heltec V3',
          ),
        ],
      );

      expect(merged.map((entry) => entry.remoteId), [
        'AA:BB:CC:DD:EE:FF',
        '11:22:33:44:55:66',
      ]);
      expect(merged.first.previouslyUsed, isTrue);
      expect(merged.first.currentlyVisible, isFalse);
      expect(merged.last.previouslyUsed, isFalse);
      expect(merged.last.currentlyVisible, isTrue);
    });

    test('marks a known device visible when the scan finds it', () {
      final merged = mergeBluetoothScanResults(
        known: const [
          KnownBluetoothDevice(
            remoteId: 'aa:bb:cc:dd:ee:ff',
            name: 'Stored Name',
          ),
        ],
        discovered: const [
          DiscoveredBluetoothDevice(
            remoteId: 'AA:BB:CC:DD:EE:FF',
            name: 'MeshCore Live',
          ),
        ],
      );

      expect(merged, hasLength(1));
      expect(merged.single.currentlyVisible, isTrue);
      expect(merged.single.previouslyUsed, isTrue);
      expect(merged.single.name, 'MeshCore Live');
    });
  });
}
