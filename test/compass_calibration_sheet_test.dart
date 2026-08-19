import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/widgets/compass_calibration.dart';

void main() {
  testWidgets('shows calibrate and later actions', (tester) async {
    var calibrate = 0;
    var later = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompassCalibrationBanner(
            onCalibrate: () => calibrate++,
            onLater: () => later++,
          ),
        ),
      ),
    );

    expect(find.text('Compass needs calibration'), findsOneWidget);
    await tester.tap(find.text('Calibrate'));
    await tester.tap(find.text('Later'));

    expect(calibrate, 1);
    expect(later, 1);
  });

  testWidgets('completes the sheet after enough heading motion', (
    tester,
  ) async {
    final events = StreamController<CompassEvent>.broadcast();
    addTearDown(events.close);
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showCompassCalibrationSheet(
                  context,
                  events: events.stream,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Calibrate compass'), findsOneWidget);
    expect(find.byType(CompassFigureEight), findsOneWidget);

    for (var heading = 0; heading < 360; heading += 15) {
      events.add(CompassEvent.fromList([heading.toDouble(), 0.0, -1.0]));
      await tester.pump();
    }

    expect(find.text('Calibration complete'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Calibrate compass'), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('skip dismisses the sheet without completing', (tester) async {
    final events = StreamController<CompassEvent>.broadcast();
    addTearDown(events.close);
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showCompassCalibrationSheet(
                  context,
                  events: events.stream,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(result, isFalse);
  });
}
