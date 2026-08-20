import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/widgets/tracking_play_button.dart';

import 'helpers/l10n_harness.dart';

void main() {
  testWidgets(
    'long-press starts a fresh session instead of showing a tooltip',
    (tester) async {
      var freshStarts = 0;
      var toggles = 0;

      await pumpWithL10n(
        tester,
        Scaffold(
          floatingActionButton: TrackingPlayButton(
            isTracking: false,
            onToggle: () => toggles++,
            onStartFreshSession: () => freshStarts++,
            onToggleQuickSettings: () {},
          ),
        ),
      );

      await tester.longPress(find.byType(FloatingActionButton));

      expect(freshStarts, 1);
      expect(toggles, 0);
      expect(find.byType(Tooltip), findsNothing);
    },
  );

  testWidgets('short press still toggles tracking', (tester) async {
    var toggles = 0;

    await pumpWithL10n(
      tester,
      Scaffold(
        floatingActionButton: TrackingPlayButton(
          isTracking: false,
          onToggle: () => toggles++,
          onStartFreshSession: () {},
          onToggleQuickSettings: () {},
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(kDoubleTapTimeout);

    expect(toggles, 1);
  });
}
