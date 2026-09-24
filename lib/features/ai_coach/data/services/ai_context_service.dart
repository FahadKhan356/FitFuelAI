import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/calorie_goal_resolver.dart';
import '../../../../core/services/water_goal_resolver.dart';
import '../../../../core/utils/fitness_calculator.dart';
import '../models/ai_user_context_model.dart';

/// Read-only "context layer" for the AI Health Coach.
///
/// Pulls the signed-in user's own history (profile, goals, meals + items, water
/// and weight entries) from Supabase, scoped to [userId] - the server enforces
/// the same scope through RLS - and turns it into a single
/// [AiUserContextModel] that is injected into the Gemini prompt.
///
/// Design notes:
/// * **Read-only** - nothing here ever writes to the database.
/// * **Graceful** - every query is guarded, so one failing table only blanks
///   its own section instead of breaking the coach.
/// * **Cheap** - results are cached for [AppConstants.aiContextCacheTtl] so
///   two messages in a row do not re-fetch the whole history.
class AiContextService {
  final SupabaseClient _client;

  final Map<String, AiUserContextModel> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  AiContextService(this._client);

  /// Builds (or returns a cached) context snapshot for [userId].
  ///
  /// Pass [forceRefresh] to bypass the cache and [now] to make the "today"
  /// window deterministic (used by tests).
  Future<AiUserContextModel> buildContext(
    String userId, {
    bool forceRefresh = false,
    DateTime? now,
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'AI coach context requires a signed-in user',
      );
    }

    final stamp = now ?? DateTime.now();
    final today = DateTime(stamp.year, stamp.month, stamp.day);

    if (!forceRefresh) {
      final cached = _cache[userId];
      final cachedAt = _cacheTimestamps[userId];
      if (cached != null &&
          cachedAt != null &&
          stamp.difference(cachedAt) < AppConstants.aiContextCacheTtl) {
        return cached;
      }
    }

    final historyStart = today.subtract(
      const Duration(days: AppConstants.aiContextHistoryDays - 1),
    );
    final weightStart = today.subtract(
      const Duration(days: AppConstants.aiContextWeightDays - 1),
    );

    // Start every query together, then await them one by one. Each future is
    // individually guarded, so a failure only blanks its own section.
    final profileFuture =
        _guard('profile', () => _fetchSingle('user_profiles', userId), null);
    final goalsFuture =
        _guard('goals', () => _fetchLatest('goals', userId), null);
    final mealsFuture = _guard(
      'meals',
      () => _fetchMeals(userId, historyStart, today),
      const <AiMealSummary>[],
    );
    final waterFuture = _guard(
      'water',
      () => _fetchWaterTotals(userId, historyStart, today),
      <String, int>{},
    );
    final weightsFuture = _guard(
      'weight',
      () => _fetchWeights(userId, weightStart),
      const <AiWeightPoint>[],
    );

    final profile = await profileFuture;
    final goals = await goalsFuture;
    final meals = await mealsFuture;
    final loggedWater = await waterFuture;
    final weights = await weightsFuture;

    // Pre-fill the entire window so "average" really means "per day in the
    // window", with days that have no entry counting as 0.
    final calorieTotals = _emptyWindow(historyStart, today);
    for (final meal in meals) {
      final key = AiUserContextModel.dateKey(meal.date);
      calorieTotals[key] = (calorieTotals[key] ?? 0) + meal.computedCalories;
    }
    final waterTotals = _emptyWindow(historyStart, today);
    loggedWater.forEach((key, value) => waterTotals[key] = value);

    final todayKey = AiUserContextModel.dateKey(today);
    final todayMeals = meals
        .where((meal) => AiUserContextModel.dateKey(meal.date) == todayKey)
        .toList();

    final context = AiUserContextModel(
      userId: userId,
      name: profile?['name'] as String?,
      age: _asInt(profile?['age']),
      gender: profile?['gender'] as String?,
      heightCm: _asDouble(profile?['height_cm']),
      currentWeightKg: _asDouble(profile?['current_weight']) ??
          _asDouble(profile?['weight_kg']) ??
          (weights.isEmpty ? null : weights.first.weightKg),
      goalWeightKg: _asDouble(profile?['goal_weight_kg']),
      activityLevel: profile?['activity_level'] as String?,
      goalType:
          profile?['goal_type'] as String? ?? goals?['goal_type'] as String?,
      dietPreference: profile?['diet_preference'] as String?,
      workoutFrequency: _asInt(profile?['workout_frequency']),
      targetCalories: await _resolveCalorieTarget(userId, goals),
      targetProtein: _asDouble(goals?['target_protein']) ?? 0,
      targetCarbs: _asDouble(goals?['target_carbs']) ?? 0,
      targetFat: _asDouble(goals?['target_fat']) ?? 0,
      dailyWaterMl: await _resolveWaterTarget(userId, goals),
      weeklyPaceKg: _asDouble(goals?['weekly_pace_kg']),
      today: today,
      caloriesConsumedToday:
          todayMeals.fold(0, (sum, meal) => sum + meal.computedCalories),
      proteinToday: _sumMacro(todayMeals, (line) => line.protein),
      carbsToday: _sumMacro(todayMeals, (line) => line.carbs),
      fatToday: _sumMacro(todayMeals, (line) => line.fat),
      waterTodayMl: waterTotals[todayKey] ?? 0,
      calorieTotalsByDate: calorieTotals,
      waterTotalsByDate: waterTotals,
      recentMeals: meals,
      weightHistory: weights,
      generatedAt: stamp,
    );

    final completed = _fillMacroTargets(context);
    _cache[userId] = completed;
    _cacheTimestamps[userId] = stamp;
    return completed;
  }

  /// Drops the cached snapshot for [userId].
  void invalidate(String userId) {
    _cache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  /// Clears every cached snapshot (e.g. on sign-out).
  void invalidateAll() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // ==================== Queries (all scoped to the user) ====================

  Future<Map<String, dynamic>?> _fetchSingle(String table, String userId) async {
    final response = await _client
        .from(table)
        .select()
        .eq('user_id', userId)
        .limit(1);
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    return null;
  }

  /// The most recently updated row in `table` for this user.
  Future<Map<String, dynamic>?> _fetchLatest(
    String table,
    String userId,
  ) async {
    final response = await _client
        .from(table)
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(1);
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    return null;
  }

  /// Meals (with their items) between [start] and [end], oldest first.
  Future<List<AiMealSummary>> _fetchMeals(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from('meals')
        .select(
          'date, meal_type, total_calories, '
          'meal_items(food_name, calories, protein, carbs, fat)',
        )
        .eq('user_id', userId)
        .gte('date', AiUserContextModel.dateKey(start))
        .lte('date', AiUserContextModel.dateKey(end))
        .order('date');

    final meals = <AiMealSummary>[];
    for (final row in response as List) {
      final map = row as Map<String, dynamic>;
      final items = ((map['meal_items'] as List<dynamic>?) ?? const [])
          .whereType<Map>()
          .map((item) => AiFoodLine.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      meals.add(AiMealSummary(
        date: DateTime.tryParse(map['date']?.toString() ?? '') ?? end,
        mealType: map['meal_type']?.toString() ?? 'meal',
        totalCalories: _asInt(map['total_calories']) ?? 0,
        items: items,
      ));
    }
    return meals.take(AppConstants.aiContextMaxRecentMeals).toList();
  }

  /// `yyyy-MM-dd` -> total ml for the window.
  Future<Map<String, int>> _fetchWaterTotals(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from('water_intake')
        .select('date, amount_ml')
        .eq('user_id', userId)
        .gte('date', AiUserContextModel.dateKey(start))
        .lte('date', AiUserContextModel.dateKey(end));

    final totals = <String, int>{};
    for (final row in response as List) {
      final map = row as Map<String, dynamic>;
      final key = map['date']?.toString();
      if (key == null) continue;
      totals[key] = (totals[key] ?? 0) + (_asInt(map['amount_ml']) ?? 0);
    }
    return totals;
  }

  /// Weight entries from [start] onwards, newest first.
  Future<List<AiWeightPoint>> _fetchWeights(
    String userId,
    DateTime start,
  ) async {
    final response = await _client
        .from('weight_entries')
        .select('date, weight_kg, bmi')
        .eq('user_id', userId)
        .gte('date', AiUserContextModel.dateKey(start))
        .order('date', ascending: false);

    final points = <AiWeightPoint>[];
    for (final row in response as List) {
      final map = row as Map<String, dynamic>;
      final date = DateTime.tryParse(map['date']?.toString() ?? '');
      final weightKg = _asDouble(map['weight_kg']) ?? 0;
      if (date == null || weightKg <= 0) continue;
      points.add(AiWeightPoint(
        date: date,
        weightKg: weightKg,
        bmi: _asDouble(map['bmi']),
      ));
    }
    return points;
  }

  /// Runs [query], falling back to [fallback] so one bad table (offline, RLS,
  /// schema drift) never takes the whole coach down.
  Future<T> _guard<T>(
    String label,
    Future<T> Function() query,
    T fallback,
  ) async {
    try {
      return await query();
    } catch (error) {
      debugPrint('AiContextService: $label query failed: $error');
      return fallback;
    }
  }

  static Map<String, int> _emptyWindow(DateTime start, DateTime end) {
    final window = <String, int>{};
    var cursor = start;
    while (!cursor.isAfter(end)) {
      window[AiUserContextModel.dateKey(cursor)] = 0;
      cursor = cursor.add(const Duration(days: 1));
    }
    return window;
  }

  static double _sumMacro(
    List<AiMealSummary> meals,
    double Function(AiFoodLine line) selector,
  ) =>
      meals.fold(
        0.0,
        (sum, meal) =>
            sum + meal.items.fold(0.0, (lineSum, line) => lineSum + selector(line)),
      );

  // ==================== Target resolution ====================

  /// Uses the goals row, then the shared app resolver (profile-based estimate)
  /// so the AI never reasons against a `0 kcal` target.
  Future<int> _resolveCalorieTarget(
    String userId,
    Map<String, dynamic>? goals,
  ) async {
    final stored = _asInt(goals?['target_calories']) ?? 0;
    if (stored > 0) return stored;
    try {
      return await CalorieGoalResolver.resolve(userId);
    } catch (error) {
      debugPrint('AiContextService: calorie target fallback failed: $error');
      return CalorieGoalResolver.defaultCalories;
    }
  }

  Future<int> _resolveWaterTarget(
    String userId,
    Map<String, dynamic>? goals,
  ) async {
    final stored = _asInt(goals?['daily_water_ml']) ?? 0;
    if (stored > 0) return stored;
    try {
      return await WaterGoalResolver.resolve(userId);
    } catch (error) {
      debugPrint('AiContextService: water target fallback failed: $error');
      return WaterGoalResolver.defaultWaterMl;
    }
  }

  /// Derives protein/carbs/fat targets for accounts whose goals row has a
  /// calorie target but zeroed macros, using the same formulas as onboarding.
  static AiUserContextModel _fillMacroTargets(AiUserContextModel context) {
    if (context.targetCalories <= 0) return context;

    var protein = context.targetProtein;
    var fat = context.targetFat;
    var carbs = context.targetCarbs;

    final weight = context.currentWeightKg;
    if (protein <= 0 && weight != null && weight > 0) {
      protein = FitnessCalculator.calculateProtein(weightKg: weight);
    }
    if (fat <= 0) {
      fat = FitnessCalculator.calculateFat(
        targetCalories: context.targetCalories,
      );
    }
    if (carbs <= 0 && protein > 0 && fat > 0) {
      carbs = FitnessCalculator.calculateCarbs(
        targetCalories: context.targetCalories,
        targetProtein: protein,
        targetFat: fat,
      );
    }

    if (protein == context.targetProtein &&
        carbs == context.targetCarbs &&
        fat == context.targetFat) {
      return context;
    }

    return context.copyWith(
      targetProtein: protein,
      targetCarbs: carbs,
      targetFat: fat,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
