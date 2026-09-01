import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/models/location_quality_settings.dart';
import 'package:meshcore_wardrive/services/bad_fix_monitor.dart';

void main() {
  group('BadFixMonitor', () {
    test('does not pause below the configured streak', () {
      final monitor = BadFixMonitor(requiredBadFixes: 5);

      monitor.recordRejectedFix();
      monitor.recordRejectedFix();
      monitor.recordRejectedFix();
      monitor.recordRejectedFix();

      expect(monitor.isPaused, isFalse);
      expect(monitor.consecutiveBadFixes, 4);
    });

    test('pauses after the configured number of consecutive bad fixes', () {
      final monitor = BadFixMonitor(
        requiredBadFixes:
            LocationQualitySettings.defaultPingPauseBadFixCount, // 5
      );

      for (var i = 0; i < 4; i++) {
        monitor.recordRejectedFix();
      }
      expect(monitor.isPaused, isFalse);

      monitor.recordRejectedFix();
      expect(monitor.isPaused, isTrue);
    });

    test('stays paused while the bad fixes keep coming', () {
      final monitor = BadFixMonitor(requiredBadFixes: 3);

      for (var i = 0; i < 10; i++) {
        monitor.recordRejectedFix();
      }

      expect(monitor.isPaused, isTrue);
    });

    test('a single accepted fix clears the streak and unpauses', () {
      final monitor = BadFixMonitor(requiredBadFixes: 2);

      monitor.recordRejectedFix();
      monitor.recordRejectedFix();
      expect(monitor.isPaused, isTrue);

      monitor.recordAcceptedFix();
      expect(monitor.isPaused, isFalse);
      expect(monitor.consecutiveBadFixes, 0);
    });

    test('reset clears an engaged pause', () {
      final monitor = BadFixMonitor(requiredBadFixes: 1);

      monitor.recordRejectedFix();
      expect(monitor.isPaused, isTrue);

      monitor.reset();
      expect(monitor.isPaused, isFalse);
    });

    test('pauses immediately with a threshold of one', () {
      final monitor = BadFixMonitor(requiredBadFixes: 1);

      expect(monitor.isPaused, isFalse);

      monitor.recordRejectedFix();
      expect(monitor.isPaused, isTrue);
    });

    test('applies threshold changes to the recorded streak immediately', () {
      final monitor = BadFixMonitor(requiredBadFixes: 5);

      for (var i = 0; i < 5; i++) {
        monitor.recordRejectedFix();
      }
      expect(monitor.isPaused, isTrue);

      // Raising the threshold retroactively unpauses the same streak.
      monitor.requiredBadFixes = 10;
      expect(monitor.isPaused, isFalse);

      // Lowering it re-engages the pause without new rejections.
      monitor.requiredBadFixes = 3;
      expect(monitor.isPaused, isTrue);
    });
  });
}
