import 'package:flutter/services.dart';

class AndroidTrackingSettingsService {
  static const MethodChannel _channel = MethodChannel(
    'mintylinux.meshcore.wardrive/tracking_settings',
  );

  Future<bool?> isWifiScanThrottlingEnabled() {
    return _channel.invokeMethod<bool>('isWifiScanThrottlingEnabled');
  }

  Future<bool> openWifiScanThrottlingSettings() async {
    return await _channel.invokeMethod<bool>(
          'openWifiScanThrottlingSettings',
        ) ??
        false;
  }
}
