import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/achievement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isLegendCompanionName', () {
    test('matches the legend prefixes at the start of the name', () {
      expect(AchievementService.isLegendCompanionName('Ya_Smolensk'), isTrue);
      expect(AchievementService.isLegendCompanionName('Yakut'), isTrue);
      expect(AchievementService.isLegendCompanionName('Якут'), isTrue);
    });

    test('matching ignores case and surrounding whitespace', () {
      expect(AchievementService.isLegendCompanionName('ya_smolensk'), isTrue);
      expect(AchievementService.isLegendCompanionName('YAKUTIA'), isTrue);
      expect(
        AchievementService.isLegendCompanionName('якут-66'),
        isTrue,
        reason: 'Cyrillic names lowercase to the same prefix',
      );
      expect(AchievementService.isLegendCompanionName('  Yakut_1 '), isTrue);
    });

    test('rejects names without a legend prefix', () {
      expect(AchievementService.isLegendCompanionName(null), isFalse);
      expect(AchievementService.isLegendCompanionName(''), isFalse);
      expect(AchievementService.isLegendCompanionName('Yaku'), isFalse);
      expect(AchievementService.isLegendCompanionName('My_Ya_node'), isFalse);
      expect(
        AchievementService.isLegendCompanionName('Legend Ya_Smolensk'),
        isFalse,
        reason: 'the prefix must start the name',
      );
      expect(AchievementService.isLegendCompanionName('Смоленск'), isFalse);
    });
  });

  group('totalDistanceInUnits', () {
    test('scales the total into miles when the unit setting is miles', () {
      expect(
        AchievementService.totalDistanceInUnits(1609.34, 'miles'),
        closeTo(1, 1e-9),
      );
      expect(
        AchievementService.totalDistanceInUnits(160934, 'miles'),
        closeTo(100, 1e-9),
        reason: 'the miles_100 threshold unlocks at 100 real miles',
      );
    });

    test('scales the total into kilometers when the unit setting is km', () {
      expect(
        AchievementService.totalDistanceInUnits(1000, 'km'),
        closeTo(1, 1e-9),
      );
      expect(
        AchievementService.totalDistanceInUnits(100000, 'km'),
        closeTo(100, 1e-9),
        reason: 'the miles_100 threshold unlocks at 100 km with no conversion',
      );
    });

    test('treats unknown units as the legacy miles scale', () {
      expect(
        AchievementService.totalDistanceInUnits(1609.34, ''),
        closeTo(1, 1e-9),
      );
    });
  });

  group('getAll', () {
    test('reports the hidden flag and unlock state from preferences', () async {
      final unlockedAt = DateTime.utc(2026, 3, 2);
      SharedPreferences.setMockInitialValues({
        'achievement_smolensk_legend': unlockedAt.millisecondsSinceEpoch,
      });

      final all = await AchievementService().getAll();
      final legend = all.firstWhere((a) => a.id == 'smolensk_legend');
      final firstPing = all.firstWhere((a) => a.id == 'first_ping');

      expect(legend.hidden, isTrue);
      expect(legend.unlocked, isTrue);
      expect(
        legend.unlockedAt!.millisecondsSinceEpoch,
        unlockedAt.millisecondsSinceEpoch,
      );
      expect(firstPing.hidden, isFalse);
      expect(firstPing.unlocked, isFalse);
    });
  });
}
