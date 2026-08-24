import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/l10n/achievement_l10n.dart';

import '../helpers/l10n_harness.dart';

void main() {
  testWidgets(
    'english distance achievement copy follows the selected distance unit',
    (tester) async {
      final l10n = await pumpWithL10n(tester, const SizedBox.shrink());

      expect(
        achievementCopy(l10n, 'miles_10').description,
        'Drive 10 km wardriving',
        reason: 'the app default unit is km',
      );
      expect(
        achievementCopy(l10n, 'miles_10', distanceUnit: 'miles').description,
        'Drive 10 miles wardriving',
      );
      expect(
        achievementCopy(l10n, 'miles_100', distanceUnit: 'km').description,
        'Drive 100 km wardriving',
      );
      expect(
        achievementCopy(l10n, 'miles_500', distanceUnit: 'miles').description,
        'Drive 500 miles wardriving',
      );
    },
  );

  testWidgets(
    'russian distance achievement copy follows the selected distance unit',
    (tester) async {
      final l10n = await pumpWithL10n(
        tester,
        const SizedBox.shrink(),
        locale: const Locale('ru'),
      );

      expect(
        achievementCopy(l10n, 'miles_100').description,
        'Проедьте 100 км в режиме вардрайва',
      );
      expect(
        achievementCopy(l10n, 'miles_100', distanceUnit: 'miles').description,
        'Проедьте 100 миль в режиме вардрайва',
      );
    },
  );

  testWidgets('non-distance achievements ignore the distance unit', (
    tester,
  ) async {
    final l10n = await pumpWithL10n(tester, const SizedBox.shrink());

    expect(achievementCopy(l10n, 'pings_100').description, 'Send 100 pings');
  });
}
