import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('io.github.xarleyn.meshcore.wardrive/feedback');
  final toneCalls = <Map<Object?, Object?>>[];
  final vibrateCalls = <Map<Object?, Object?>>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    toneCalls.clear();
    vibrateCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final arguments = Map<Object?, Object?>.from(call.arguments! as Map);
          switch (call.method) {
            case 'playTone':
              toneCalls.add(arguments);
              return null;
            case 'vibrate':
              vibrateCalls.add(arguments);
              return true;
          }
          return null;
        });
    // Reset the singleton runtime toggles before each scenario.
    SoundService().setEnabled(true);
    SoundService().setVibrationEnabled(true);
    await SoundService().init();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('link lost alert plays a repeated tone plus double vibration', () async {
    await SoundService().playLinkLost();

    expect(toneCalls.length, 2);
    expect(
      toneCalls.every(
        (call) => call['tone'] == AndroidTones.TONE_CDMA_ABBR_ALERT,
      ),
      isTrue,
    );
    expect(vibrateCalls.length, 2);
    expect(vibrateCalls.every((call) => call['durationMs'] == 200), isTrue);
  });

  test(
    'link lost alert stays silent when sound feedback is disabled',
    () async {
      SoundService().setEnabled(false);

      await SoundService().playLinkLost();

      expect(toneCalls, isEmpty);
      expect(vibrateCalls, isNotEmpty);
    },
  );

  test('link lost alert skips haptics when vibration is disabled', () async {
    SoundService().setVibrationEnabled(false);

    await SoundService().playLinkLost();

    expect(toneCalls, isNotEmpty);
    expect(vibrateCalls, isEmpty);
  });

  test('link lost alert does nothing when both toggles are disabled', () async {
    SoundService().setEnabled(false);
    SoundService().setVibrationEnabled(false);

    await SoundService().playLinkLost();

    expect(toneCalls, isEmpty);
    expect(vibrateCalls, isEmpty);
  });
}
