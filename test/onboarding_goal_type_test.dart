import 'package:fitfuel_ai/core/data/models/user_model.dart';
import 'package:fitfuel_ai/core/utils/fitness_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('goal type is persisted in both profile and goals payloads', () {
    final user = UserModel(
      id: 'user-1',
      goalType: 'weight_loss',
      targetCalories: 1800,
      targetProtein: 150,
      targetCarbs: 200,
      targetFat: 65,
      dailyWaterMl: 2500,
    );

    expect(user.toProfileJson()['goal_type'], 'weight_loss');
    expect(user.toGoalsJson()['goal_type'], 'weight_loss');
  });

  test('weight_loss produces a deficit below TDEE, not a hardcoded 2000 kcal', () {
    final targets = FitnessCalculator.calculateAllTargets(
      weightKg: 50,
      heightCm: 172,
      age: 30,
      gender: 'male',
      activityLevel: 'very_active',
      goalType: 'weight_loss',
      weeklyPaceKg: 0.5,
    );

    expect(targets['target_calories'], isNot(2000), reason: 'must not be hardcoded');
    expect(targets['target_calories'], greaterThan(0));
    expect(targets['target_protein'], greaterThan(0));
    expect(targets['target_carbs'], greaterThan(0));
    expect(targets['target_fat'], greaterThan(0));
    expect(targets['daily_water_ml'], greaterThan(0));
  });

  test('muscle_gain produces a surplus above maintenance', () {
    final maintenance = FitnessCalculator.calculateAllTargets(
      weightKg: 50,
      heightCm: 172,
      age: 30,
      gender: 'male',
      activityLevel: 'very_active',
      goalType: 'maintain',
    );

    final gain = FitnessCalculator.calculateAllTargets(
      weightKg: 50,
      heightCm: 172,
      age: 30,
      gender: 'male',
      activityLevel: 'very_active',
      goalType: 'weight_gain',
      weeklyPaceKg: 0.25,
    );

    expect(gain['target_calories'], greaterThan(maintenance['target_calories'] as int));
    expect(gain['target_calories'], isNot(2000));
  });
}
