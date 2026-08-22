import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/widgets/compass_calibration.dart';

import '../helpers/l10n_harness.dart';

void main() {
  testWidgets('shows calibrate and later actions', (tester) async {
    var calibrate = 0;
    var later = 0;

    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
        body: CompassCalibrationBanner(
          onCalibrate: () => calibrate++,
          onLater: () => later++,
        ),
      ),
    );

    expect(find.text(l10n.compassNeedsCalibration), findsOneWidget);
    await tester.tap(find.text(l10n.compassCalibrate));
    await tester.tap(find.text(l10n.compassLater));

    expect(calibrate, 1);
    expect(later, 1);
  });

  testWidgets('sits above the system navigation inset like the map FABs', (
    tester,
  ) async {
    const viewSize = Size(400, 800);
    const navBarHeight = 48.0;
    tester.view.physicalSize = viewSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      MediaQuery(
        data: const MediaQueryData(
          size: viewSize,
          viewPadding: EdgeInsets.only(bottom: navBarHeight),
          padding: EdgeInsets.only(bottom: navBarHeight),
        ),
        child: Scaffold(
          body: Stack(
            children: [
              CompassCalibrationMapBanner(onCalibrate: () {}, onLater: () {}),
            ],
          ),
        ),
      ),
    );

    final banner = tester.getRect(find.byType(CompassCalibrationBanner));
    expect(
      banner.bottom,
      viewSize.height - navBarHeight - kFloatingActionButtonMargin,
    );
  });

  testWidgets('completes the sheet after enough heading motion', (
    tester,
  ) async {
    final events = StreamController<CompassEvent>.broadcast();
    addTearDown(events.close);
    bool? result;

    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
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
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.compassSheetTitle), findsOneWidget);
    expect(find.byType(CompassFigureEight), findsOneWidget);

    for (var heading = 0; heading < 360; heading += 15) {
      events.add(CompassEvent.fromList([heading.toDouble(), 0.0, -1.0]));
      await tester.pump();
    }

    expect(find.text(l10n.compassCalibrationComplete), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.compassSheetTitle), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('skip dismisses the sheet without completing', (tester) async {
    final events = StreamController<CompassEvent>.broadcast();
    addTearDown(events.close);
    bool? result;

    final l10n = await pumpWithL10n(
      tester,
      Scaffold(
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
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(l10n.compassSkip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(result, isFalse);
  });
}
