import '../di/service_locator.dart';
import '../domain/repositories/user_repository.dart';
import '../utils/fitness_calculator.dart';

/// Single source of truth for the daily calorie (and macro) goal.
///
/// The `goals` row's target columns were made nullable by
/// `002_remove_goal_defaults.sql`, so the stored row can carry `0`/`null`
/// targets when the server-side `calculate_user_goals` RPC hasn't run. To keep
/// the home, calendar and tracker screens from showing a broken `0` goal (which
/// also breaks the calendar's goal-met tick/cross), we resolve in this order:
///   1. The user's goal row (`targetCalories`) if present and > 0.
///   2. A profile-based estimate via FitnessCalculator (same as home screen).
///   3. A safe last-resort default of 2000 kcal.
class CalorieGoalResolver {
  const CalorieGoalResolver._();

  static const int defaultCalories = 2000;

  static Future<int> resolve(String userId) async {
    final repo = sl<UserRepository>();

    // 1) DB goal row.
    try {
      final goals = await repo.getUserGoals(userId);
      final db = goals?.targetCalories;
      if (db != null && db > 0) return db;
    } catch (_) {}

    // 2) Profile-based fallback (identical formula to home screen).
    try {
      final profile = await repo.getUserProfile(userId);
      // Use live current weight when available, else fall back to start weight.
      final weight = profile?.currentWeightKg ?? profile?.weightKg;
      if (profile != null &&
          weight != null &&
          profile.heightCm != null &&
          profile.age != null &&
          profile.gender != null &&
          profile.activityLevel != null) {
        final bmr = FitnessCalculator.calculateBMR(
          weightKg: weight,
          heightCm: profile.heightCm!,
          age: profile.age!,
          gender: profile.gender!,
        );
        final tdee = FitnessCalculator.calculateTDEE(
          bmr: bmr,
          activityLevel: profile.activityLevel!,
        );
        final calories = FitnessCalculator.calculateTargetCalories(
          tdee: tdee,
          goalType: profile.goalType ?? 'maintain',
          weeklyPaceKg: 0.5,
        );
        if (calories > 0) return calories;
      }
    } catch (_) {}

    // 3) Safe default.
    return defaultCalories;
  }
}