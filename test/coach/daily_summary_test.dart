import 'package:fitfuel_ai/features/coach/providers/daily_summary_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailySummary calculations & formatting', () {
    test('calculates correct percentages and formatted labels', () {
      final summary = DailySummary(
        caloriesConsumed: 411,
        caloriesGoal: 3097,
        waterMl: 1500,
        waterGoalMl: 3000,
        proteinG: 28,
        proteinGoalG: 140,
        carbsG: 7,
        carbsGoalG: 441,
        fatsG: 12,
        fatsGoalG: 70,
        streakDays: 2,
        lastSyncedAt: DateTime.now(),
      );

      expect(summary.caloriesLabel, '411 kcal');
      expect(summary.waterL, '1.5 L');
      expect(summary.proteinLabel, '28 g');

      expect(summary.caloriePercent, 13);
      expect(summary.waterPercent, 50);
      expect(summary.proteinPercent, 20);
    });

    test('handles zero goals without dividing by zero', () {
      final summary = DailySummary(
        caloriesConsumed: 100,
        caloriesGoal: 0,
        waterMl: 0,
        waterGoalMl: 0,
        proteinG: 0,
        proteinGoalG: 0,
        carbsG: 0,
        carbsGoalG: 0,
        fatsG: 0,
        fatsGoalG: 0,
        streakDays: 0,
        lastSyncedAt: DateTime.now(),
      );

      expect(summary.calorieRatio, 0.0);
      expect(summary.waterRatio, 0.0);
      expect(summary.proteinRatio, 0.0);
      expect(summary.caloriePercent, 0);
    });

    test('dailySummaryProvider updates correctly', () {
      final notifier = DailySummaryNotifier.instance;
      notifier.addWaterMl(250);

      expect(notifier.summary.waterMl >= 250, isTrue);
    });
  });
}
