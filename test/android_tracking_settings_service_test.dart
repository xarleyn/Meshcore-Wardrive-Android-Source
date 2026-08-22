import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/android_tracking_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'io.github.xarleyn.meshcore.wardrive/tracking_settings',
  );
  final service = AndroidTrackingSettingsService();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads the Android Wi-Fi scan throttling setting', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'isWifiScanThrottlingEnabled');
          return true;
        });

    expect(await service.isWifiScanThrottlingEnabled(), isTrue);
  });

  test('opens Android developer settings', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'openWifiScanThrottlingSettings');
          return true;
        });

    expect(await service.openWifiScanThrottlingSettings(), isTrue);
  });
}
