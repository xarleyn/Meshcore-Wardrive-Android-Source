import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/lora_companion_service.dart';
import 'package:meshcore_wardrive/services/reconnect_policy.dart';
import 'package:usb_serial/usb_serial.dart';

UsbDevice _usb(
  String deviceName, {
  int? vid,
  int? pid,
  String? productName,
  String? serial,
  int? deviceId,
}) {
  return UsbDevice(
    deviceName,
    vid,
    pid,
    productName,
    null,
    deviceId,
    serial,
    null,
  );
}

void main() {
  group('ReconnectBackoff', () {
    const backoff = ReconnectBackoff();

    test('doubles the delay per attempt until the cap', () {
      expect(backoff.delayForAttempt(1), const Duration(seconds: 3));
      expect(backoff.delayForAttempt(2), const Duration(seconds: 6));
      expect(backoff.delayForAttempt(3), const Duration(seconds: 12));
      expect(backoff.delayForAttempt(4), const Duration(seconds: 24));
      expect(backoff.delayForAttempt(5), const Duration(seconds: 48));
    });

    test('caps the delay at maxDelay', () {
      expect(backoff.delayForAttempt(6), const Duration(seconds: 60));
      expect(backoff.delayForAttempt(7), const Duration(seconds: 60));
      expect(backoff.delayForAttempt(100), const Duration(seconds: 60));
    });

    test('clamps non-positive attempt numbers to the first attempt', () {
      expect(backoff.delayForAttempt(0), const Duration(seconds: 3));
      expect(backoff.delayForAttempt(-5), const Duration(seconds: 3));
    });

    test('honours a custom policy', () {
      const custom = ReconnectBackoff(
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 3),
      );

      expect(custom.delayForAttempt(1), const Duration(seconds: 1));
      expect(custom.delayForAttempt(2), const Duration(seconds: 2));
      expect(custom.delayForAttempt(3), const Duration(seconds: 3));
      expect(custom.delayForAttempt(4), const Duration(seconds: 3));
    });
  });

  group('matchUsbDevice', () {
    final remembered = _usb(
      '/dev/bus/usb/001/002',
      vid: 0x1a86,
      pid: 0x55d4,
      productName: 'MeshCore Radio',
      serial: 'SERIAL42',
    );

    test('prefers a serial number plus VID/PID match', () {
      final attached = [
        _usb('/dev/bus/usb/001/009', vid: 0x1a86, pid: 0x55d4),
        _usb(
          '/dev/bus/usb/001/010',
          vid: 0x1a86,
          pid: 0x55d4,
          serial: 'SERIAL42',
        ),
      ];

      expect(matchUsbDevice(attached, remembered), same(attached[1]));
    });

    test('falls back to the interface path when serials are missing', () {
      final attached = [_usb('/dev/bus/usb/001/002', vid: 0x1a86, pid: 0x55d4)];

      expect(matchUsbDevice(attached, remembered), same(attached.single));
    });

    test('falls back to bare VID/PID after a replug changes the path', () {
      final attached = [
        _usb('/dev/bus/usb/002/007', vid: 0x1a86, pid: 0x55d4, serial: 'OTHER'),
      ];

      expect(matchUsbDevice(attached, remembered), same(attached.single));
    });

    test('returns null when the remembered device is not attached', () {
      final attached = [_usb('/dev/bus/usb/001/002', vid: 0x10c4, pid: 0xea60)];

      expect(matchUsbDevice(attached, remembered), isNull);
    });

    test('returns null for an empty attachment list', () {
      expect(matchUsbDevice(const [], remembered), isNull);
    });
  });

  group('ReconnectStatus', () {
    test('defaults to an inactive, non-restored snapshot', () {
      const status = ReconnectStatus(active: true, nextAttempt: 2);

      expect(status.active, isTrue);
      expect(status.nextAttempt, 2);
      expect(status.deviceName, isNull);
      expect(status.restored, isFalse);
    });
  });
}
