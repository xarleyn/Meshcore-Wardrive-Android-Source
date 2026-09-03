import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/screen_wake_service.dart';

void main() {
  test('keeps wakelock enabled until every reason is cleared', () async {
    final appliedStates = <bool>[];
    final service = ScreenWakeService(
      setWakelock: (enabled) async => appliedStates.add(enabled),
    );

    await service.setAlwaysOn(true);
    await service.setTrackingActive(true);
    await service.setAlwaysOn(false);
    await service.setTrackingActive(false);

    expect(appliedStates, [true, false]);
  });

  test('does not repeat an unchanged platform request', () async {
    final appliedStates = <bool>[];
    final service = ScreenWakeService(
      setWakelock: (enabled) async => appliedStates.add(enabled),
    );

    await service.setAlwaysOn(false);
    await service.setAlwaysOn(false);

    expect(appliedStates, [false]);
  });
}
