import 'package:wakelock_plus/wakelock_plus.dart';

typedef WakelockSetter = Future<void> Function(bool enabled);

/// Coordinates the reasons that may require the display to stay awake.
///
/// WakelockPlus is a single platform flag, so one feature must not disable it
/// while another feature still needs it.
class ScreenWakeService {
  ScreenWakeService({WakelockSetter? setWakelock})
    : _setWakelock = setWakelock ?? _setPlatformWakelock;

  static final ScreenWakeService instance = ScreenWakeService();

  final WakelockSetter _setWakelock;
  bool _alwaysOn = false;
  bool _trackingActive = false;
  bool? _lastRequestedState;
  bool? _lastAppliedState;
  Future<void> _pendingUpdate = Future<void>.value();

  Future<void> setAlwaysOn(bool enabled) {
    _alwaysOn = enabled;
    return _scheduleUpdate();
  }

  Future<void> setTrackingActive(bool active) {
    _trackingActive = active;
    return _scheduleUpdate();
  }

  Future<void> _scheduleUpdate() {
    final requestedState = _alwaysOn || _trackingActive;
    if (_lastRequestedState == requestedState) return _pendingUpdate;

    _lastRequestedState = requestedState;
    _pendingUpdate = _pendingUpdate.then((_) async {
      final latestState = _alwaysOn || _trackingActive;
      if (_lastAppliedState == latestState) return;
      await _setWakelock(latestState);
      _lastAppliedState = latestState;
    });
    return _pendingUpdate;
  }

  static Future<void> _setPlatformWakelock(bool enabled) {
    return WakelockPlus.toggle(enable: enabled);
  }
}
