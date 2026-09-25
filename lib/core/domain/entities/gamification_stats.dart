/// Immutable snapshot of the counters returned by the
/// `compute_gamification_stats()` RPC.
///
/// This type deliberately holds *counts only* — no XP, no levels and no badge
/// decisions. Those rules live in `lib/core/utils/xp_engine.dart` so they can
/// be unit tested without a database, which is why this stays a dumb value
/// object with no Flutter imports.
///
/// Two families of values are exposed:
///  * rolling counters (7/30-day windows) used for badge progress, and
///  * `...Today` flags used to award the day's XP.
class GamificationStats {
  const GamificationStats({
    this.authenticated = false,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.daysLogged7 = 0,
    this.mealsLogged = 0,
    this.mealsLogged30 = 0,
    this.waterDays = 0,
    this.weightEntries = 0,
    this.weightEntries30 = 0,
    this.scansCount = 0,
    this.coachMessages = 0,
    this.distinctFoods = 0,
    this.waterGoalDays30 = 0,
    this.proteinGoalDays30 = 0,
    this.perfectDays30 = 0,
    this.breakfastDays7 = 0,
    this.profileComplete = false,
    this.mealLoggedToday = false,
    this.breakfastToday = false,
    this.waterLoggedToday = false,
    this.waterGoalHitToday = false,
    this.weightLoggedToday = false,
    this.scanToday = false,
    this.coachToday = false,
    this.perfectDayToday = false,
    this.proteinGoalToday = false,
    this.targetCalories = 0,
    this.targetWaterMl = 0,
    this.xpTotal = 0,
    this.xpThisWeek = 0,
    this.grantedSources = const <String>{},
    this.grantedSourcesToday = const <String>{},
  });

  factory GamificationStats.fromJson(Map<String, dynamic> json) {
    return GamificationStats(
      authenticated: _bool(json, 'authenticated'),
      currentStreakDays: _int(json, 'current_streak_days'),
      longestStreakDays: _int(json, 'longest_streak_days'),
      daysLogged7: _int(json, 'days_logged_7'),
      mealsLogged: _int(json, 'meals_logged'),
      mealsLogged30: _int(json, 'meals_logged_30'),
      waterDays: _int(json, 'water_days'),
      weightEntries: _int(json, 'weight_entries'),
      weightEntries30: _int(json, 'weight_entries_30'),
      scansCount: _int(json, 'scans_count'),
      coachMessages: _int(json, 'coach_messages'),
      distinctFoods: _int(json, 'distinct_foods'),
      waterGoalDays30: _int(json, 'water_goal_days_30'),
      proteinGoalDays30: _int(json, 'protein_goal_days_30'),
      perfectDays30: _int(json, 'perfect_days_30'),
      breakfastDays7: _int(json, 'breakfast_days_7'),
      profileComplete: _bool(json, 'profile_complete'),
      mealLoggedToday: _bool(json, 'meal_logged_today'),
      breakfastToday: _bool(json, 'breakfast_today'),
      waterLoggedToday: _bool(json, 'water_logged_today'),
      waterGoalHitToday: _bool(json, 'water_goal_hit_today'),
      weightLoggedToday: _bool(json, 'weight_logged_today'),
      scanToday: _bool(json, 'scan_today'),
      coachToday: _bool(json, 'coach_today'),
      perfectDayToday: _bool(json, 'perfect_day_today'),
      proteinGoalToday: _bool(json, 'protein_goal_today'),
      targetCalories: _int(json, 'target_calories'),
      targetWaterMl: _int(json, 'target_water_ml'),
      xpTotal: _int(json, 'xp_total'),
      xpThisWeek: _int(json, 'xp_this_week'),
      grantedSources: _strings(json, 'granted_sources'),
      grantedSourcesToday: _strings(json, 'granted_sources_today'),
    );
  }

  /// A user with no logs at all.
  static const GamificationStats empty = GamificationStats();

  final bool authenticated;

  // ── Rolling counters (badge progress) ──
  final int currentStreakDays;
  final int longestStreakDays;
  final int daysLogged7;
  final int mealsLogged;
  final int mealsLogged30;
  final int waterDays;
  final int weightEntries;
  final int weightEntries30;
  final int scansCount;
  final int coachMessages;
  final int distinctFoods;
  final int waterGoalDays30;
  final int proteinGoalDays30;
  final int perfectDays30;
  final int breakfastDays7;
  final bool profileComplete;

  // ── Today's activity (daily XP awards) ──
  final bool mealLoggedToday;
  final bool breakfastToday;
  final bool waterLoggedToday;
  final bool waterGoalHitToday;
  final bool weightLoggedToday;
  final bool scanToday;
  final bool coachToday;
  final bool perfectDayToday;
  final bool proteinGoalToday;

  // ── Targets, echoed back so the UI can explain an unmet goal ──
  final int targetCalories;
  final int targetWaterMl;

  // ── Ledger rollup ──
  final int xpTotal;
  final int xpThisWeek;

  /// Every XP source ever recorded for this user. Used to keep one-off awards
  /// (streak milestones, badge unlocks) from being granted twice.
  final Set<String> grantedSources;

  /// XP sources already recorded today, so per-day awards stay idempotent.
  final Set<String> grantedSourcesToday;

  /// Resolves the counter a badge tracks, by its [statKey].
  ///
  /// Returns 0 for an unknown key so a renamed SQL column degrades into an
  /// "unearned badge" instead of crashing the screen.
  /// `test/badge_catalog_test.dart` asserts that every `BadgeStat` key exists
  /// in the SQL snapshot, so a silent 0 should never reach production.
  int valueFor(String statKey) {
    switch (statKey) {
      case 'current_streak_days':
        return currentStreakDays;
      case 'longest_streak_days':
        return longestStreakDays;
      case 'days_logged_7':
        return daysLogged7;
      case 'meals_logged':
        return mealsLogged;
      case 'water_goal_days_30':
        return waterGoalDays30;
      case 'protein_goal_days_30':
        return proteinGoalDays30;
      case 'perfect_days_30':
        return perfectDays30;
      case 'breakfast_days_7':
        return breakfastDays7;
      case 'distinct_foods':
        return distinctFoods;
      case 'scans_count':
        return scansCount;
      case 'weight_entries':
        return weightEntries;
      case 'coach_messages':
        return coachMessages;
      case 'profile_complete':
        return profileComplete ? 1 : 0;
      default:
        return 0;
    }
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is bool) return value ? 1 : 0;
    return 0;
  }

  static bool _bool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    return false;
  }

  /// Reads a jsonb array of strings (the SQL side aggregates with
  /// `jsonb_agg`), tolerating a JSON-encoded string just in case.
  static Set<String> _strings(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Iterable) {
      return value.map((item) => item.toString()).toSet();
    }
    return const <String>{};
  }
}
