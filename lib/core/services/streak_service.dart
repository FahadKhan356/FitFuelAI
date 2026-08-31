import '../di/service_locator.dart';
import '../domain/repositories/meal_repository.dart';

/// Result of a streak computation.
class StreakInfo {
  /// Number of consecutive days (ending today, or yesterday if today hasn't
  /// had a meal logged yet) on which the user logged at least one meal.
  final int current;

  /// True when the user has logged a meal today.
  final bool todayActive;

  /// The last date ('yyyy-MM-dd') on which a meal was logged, if any.
  final String? lastActiveDate;

  const StreakInfo({
    this.current = 0,
    this.todayActive = false,
    this.lastActiveDate,
  });
}

/// Computes the user's daily meal-tracking streak.
///
/// A "streak day" is any day the user logged at least one meal item. The streak
/// counts consecutive such days, moving backwards from today. If today has no
/// meal yet but yesterday does, the streak is still "alive" (from yesterday).
///
/// Miss a full day (neither today nor yesterday active) and the streak resets
/// to 0 — it will restart at 1 once a meal is logged again.
class StreakService {
  const StreakService._();

  static Future<StreakInfo> compute(String userId) async {
    final now = DateTime.now();

    // Look back up to a little more than a year of meal history.
    final start = now.subtract(const Duration(days: 400));
    final totals = await sl<MealRepository>()
        .getCalorieTotalsByDateRange(userId, start, now);

    final active = <String>{};
    for (final entry in totals.entries) {
      if (entry.value > 0) {
        active.add(entry.key);
      }
    }
    if (active.isEmpty) {
      return const StreakInfo(current: 0, todayActive: false);
    }

    final todayKey = _key(now);
    final yesterdayKey = _key(now.subtract(const Duration(days: 1)));

    final todayActive = active.contains(todayKey);

    // Start counting from today if active, otherwise count from yesterday
    // (today is still pending). If neither, the streak is broken.
    DateTime cursor;
    if (todayActive) {
      cursor = now;
    } else if (active.contains(yesterdayKey)) {
      cursor = now.subtract(const Duration(days: 1));
    } else {
      // Find the most recent active day for informational purposes.
      return StreakInfo(
        current: 0,
        todayActive: false,
        lastActiveDate: _mostRecent(active),
      );
    }

    var streak = 0;
    final seen = <String>{};
    while (true) {
      final key = _key(cursor);
      if (!active.contains(key) || !seen.add(key)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return StreakInfo(
      current: streak,
      todayActive: todayActive,
      lastActiveDate: todayActive
          ? todayKey
          : (active.contains(yesterdayKey) ? yesterdayKey : null),
    );
  }

  static String _key(DateTime d) => d.toIso8601String().split('T').first;

  static String? _mostRecent(Set<String> keys) {
    String? max;
    for (final k in keys) {
      if (max == null || k.compareTo(max) > 0) max = k;
    }
    return max;
  }
}