import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/utils/compass_calibration.dart';

void main() {
  group('CompassAccuracyMonitor', () {
    test('stays unknown during the initial unreliable window', () {
      final monitor = CompassAccuracyMonitor();
      final start = DateTime.utc(2026, 8, 19, 12);

      final status = monitor.observe(
        now: start.add(const Duration(seconds: 2)),
        heading: 90,
        accuracy: null,
      );

      expect(status, CompassAccuracyStatus.unknown);
    });

    test('asks for calibration after sustained unreliable readings', () {
      final monitor = CompassAccuracyMonitor();
      final start = DateTime.utc(2026, 8, 19, 12);

      monitor.observe(now: start, heading: 10, accuracy: null);
      final status = monitor.observe(
        now: start.add(const Duration(seconds: 3)),
        heading: 12,
        accuracy: null,
      );

      expect(status, CompassAccuracyStatus.needsCalibration);
    });

    test('treats low accuracy as a calibration request after the hold', () {
      final monitor = CompassAccuracyMonitor();
      final start = DateTime.utc(2026, 8, 19, 12);

      monitor.observe(now: start, heading: 10, accuracy: 45);
      final status = monitor.observe(
        now: start.add(CompassCalibrationPolicy.unreliableHold),
        heading: 11,
        accuracy: 45,
      );

      expect(status, CompassAccuracyStatus.needsCalibration);
    });

    test('becomes reliable immediately on medium or high accuracy', () {
      final monitor = CompassAccuracyMonitor();
      final start = DateTime.utc(2026, 8, 19, 12);

      monitor.observe(now: start, heading: 10, accuracy: null);
      monitor.observe(
        now: start.add(const Duration(seconds: 3)),
        heading: 10,
        accuracy: null,
      );

      expect(
        monitor.observe(
          now: start.add(const Duration(seconds: 4)),
          heading: 8,
          accuracy: 30,
        ),
        CompassAccuracyStatus.reliable,
      );
      expect(
        monitor.observe(
          now: start.add(const Duration(seconds: 5)),
          heading: 8,
          accuracy: 15,
        ),
        CompassAccuracyStatus.reliable,
      );
    });

    test('ignores events without a usable heading', () {
      final monitor = CompassAccuracyMonitor();
      final start = DateTime.utc(2026, 8, 19, 12);

      expect(
        monitor.observe(now: start, heading: null, accuracy: null),
        CompassAccuracyStatus.unknown,
      );
      expect(
        monitor.observe(
          now: start.add(const Duration(seconds: 5)),
          heading: double.nan,
          accuracy: null,
        ),
        CompassAccuracyStatus.unknown,
      );
    });

    test('restarts the unreliable hold after a reliable reading', () {
      final monitor = CompassAccuracyMonitor();
      final start = DateTime.utc(2026, 8, 19, 12);

      monitor.observe(now: start, heading: 1, accuracy: 15);
      monitor.observe(
        now: start.add(const Duration(seconds: 1)),
        heading: 2,
        accuracy: null,
      );

      expect(
        monitor.observe(
          now: start.add(const Duration(seconds: 3)),
          heading: 3,
          accuracy: null,
        ),
        CompassAccuracyStatus.reliable,
      );

      expect(
        monitor.observe(
          now: start
              .add(const Duration(seconds: 1))
              .add(CompassCalibrationPolicy.unreliableHold),
          heading: 4,
          accuracy: null,
        ),
        CompassAccuracyStatus.needsCalibration,
      );
    });
  });

  group('CompassCalibrationSampler', () {
    test('starts empty and fills as the heading covers more of the circle', () {
      final sampler = CompassCalibrationSampler();

      expect(sampler.progress, 0);

      sampler.addHeading(0);
      sampler.addHeading(10);
      expect(sampler.progress, greaterThan(0));
      expect(sampler.progress, lessThan(0.4));

      for (var heading = 0; heading < 360; heading += 20) {
        sampler.addHeading(heading.toDouble());
      }

      expect(sampler.progress, greaterThanOrEqualTo(0.8));
      expect(sampler.isComplete, isTrue);
    });

    test('counts wrapped heading motion toward completion', () {
      final sampler = CompassCalibrationSampler();

      sampler.addHeading(350);
      sampler.addHeading(10);
      sampler.addHeading(30);

      expect(sampler.progress, greaterThan(0.1));
    });
  });

  group('CompassCalibrationPolicy', () {
    final now = DateTime.utc(2026, 8, 19, 12);

    test('hides the banner unless the compass is in use and needs help', () {
      expect(
        CompassCalibrationPolicy.shouldShowBanner(
          status: CompassAccuracyStatus.needsCalibration,
          compassInUse: false,
          now: now,
        ),
        isFalse,
      );
      expect(
        CompassCalibrationPolicy.shouldShowBanner(
          status: CompassAccuracyStatus.unknown,
          compassInUse: true,
          now: now,
        ),
        isFalse,
      );
      expect(
        CompassCalibrationPolicy.shouldShowBanner(
          status: CompassAccuracyStatus.reliable,
          compassInUse: true,
          now: now,
        ),
        isFalse,
      );
      expect(
        CompassCalibrationPolicy.shouldShowBanner(
          status: CompassAccuracyStatus.needsCalibration,
          compassInUse: true,
          now: now,
        ),
        isTrue,
      );
    });

    test(
      'respects the quiet period after postpone or a successful calibration',
      () {
        expect(
          CompassCalibrationPolicy.shouldShowBanner(
            status: CompassAccuracyStatus.needsCalibration,
            compassInUse: true,
            now: now,
            quietUntil: now.add(const Duration(hours: 1)),
          ),
          isFalse,
        );
        expect(
          CompassCalibrationPolicy.shouldShowBanner(
            status: CompassAccuracyStatus.needsCalibration,
            compassInUse: true,
            now: now.add(const Duration(hours: 24)),
            quietUntil: now.add(const Duration(hours: 23)),
          ),
          isTrue,
        );
      },
    );

    test('classifies plugin accuracy values', () {
      expect(CompassCalibrationPolicy.isReliable(15), isTrue);
      expect(CompassCalibrationPolicy.isReliable(30), isTrue);
      expect(CompassCalibrationPolicy.isReliable(45), isFalse);
      expect(CompassCalibrationPolicy.isReliable(null), isFalse);
    });
  });
}
