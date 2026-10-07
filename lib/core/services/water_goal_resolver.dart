import '../di/service_locator.dart';
import '../domain/repositories/user_repository.dart';
import '../services/home_data_cache.dart';
import '../utils/fitness_calculator.dart';

/// Single source of truth for the daily water goal.
///
/// Home screen and water tracker both use this so they can never show a
/// different target. Resolution order:
///   0. In-memory cache snapshot (0ms latency, eliminates frame drops / lag).
///   1. The user's goal row (`daily_water_ml`) if present and > 0.
///   2. Weight-based estimate from the user profile (same formula everywhere).
///   3. A safe last-resort default of 2000 ml.
class WaterGoalResolver {
  const WaterGoalResolver._();

  /// The value used by both screens before the async fetch resolves, so they
  /// render the same number from frame 1 (matches home screen's initial).
  static const int defaultWaterMl = 2000;

  static Future<int> resolve(String userId) async {
    // 0) In-memory cache check (instant 0ms).
    final cached = HomeDataCache.getCached(userId);
    if (cached != null && cached.targetWaterMl > 0) {
      return cached.targetWaterMl;
    }

    final repo = sl<UserRepository>();

    // 1) DB goal row.
    try {
      final goals = await repo.getUserGoals(userId);
      final db = goals?.dailyWaterMl;
      if (db != null && db > 0) return db;
    } catch (_) {}

    // 2) Weight-based fallback (identical to home screen's fallback).
    try {
      final profile = await repo.getUserProfile(userId);
      // Prefer live current weight, fall back to start weight.
      final weight = profile?.currentWeightKg ?? profile?.weightKg;
      final activity = profile?.activityLevel;
      if (weight != null && activity != null) {
        final computed = FitnessCalculator.calculateDailyWater(
          weightKg: weight,
          activityLevel: activity,
        );
        if (computed > 0) return computed.toInt();
      }
    } catch (_) {}

    // 3) Safe default.
    return defaultWaterMl;
  }
}