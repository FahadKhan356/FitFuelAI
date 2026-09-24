/// A single tracked food line (one `meal_items` row).
class AiFoodLine {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const AiFoodLine({
    required this.name,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  factory AiFoodLine.fromJson(Map<String, dynamic> json) => AiFoodLine(
        name: json['food_name']?.toString() ?? 'Unknown food',
        calories: _toInt(json['calories']),
        protein: _toDouble(json['protein']),
        carbs: _toDouble(json['carbs']),
        fat: _toDouble(json['fat']),
      );
}

/// A logged meal (`meals` row) plus its items.
class AiMealSummary {
  final DateTime date;
  final String mealType;
  final int totalCalories;
  final List<AiFoodLine> items;

  const AiMealSummary({
    required this.date,
    required this.mealType,
    this.totalCalories = 0,
    this.items = const [],
  });

  /// Sum of the item calories. Used instead of the denormalized
  /// `total_calories` column so the coach always agrees with what the home and
  /// calendar screens display.
  int get computedCalories => items.isEmpty
      ? totalCalories
      : items.fold(0, (sum, item) => sum + item.calories);
}

/// One `weight_entries` row.
class AiWeightPoint {
  final DateTime date;
  final double weightKg;
  final double? bmi;

  const AiWeightPoint({required this.date, required this.weightKg, this.bmi});
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;

/// Immutable, read-only snapshot of everything the AI Health Coach is allowed
/// to know about a user: profile, goals, today's intake, the last 7 days of
/// calories/water and the last 30 days of weight.
///
/// It is rebuilt by `AiContextService` on every request (cached briefly) and
/// never writes anything back to Supabase.
class AiUserContextModel {
  final String userId;

  // ---- Profile (user_profiles) ----
  final String? name;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? currentWeightKg;
  final double? goalWeightKg;
  final String? activityLevel;
  final String? goalType;
  final String? dietPreference;
  final int? workoutFrequency;

  // ---- Targets (goals row + resolver fallbacks) ----
  final int targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final int dailyWaterMl;
  final double? weeklyPaceKg;

  // ---- Today ----
  final DateTime today;
  final int caloriesConsumedToday;
  final double proteinToday;
  final double carbsToday;
  final double fatToday;
  final int waterTodayMl;

  // ---- History ----
  /// `yyyy-MM-dd` -> kcal, oldest first.
  final Map<String, int> calorieTotalsByDate;

  /// `yyyy-MM-dd` -> ml, oldest first.
  final Map<String, int> waterTotalsByDate;
  final List<AiMealSummary> recentMeals;
  final List<AiWeightPoint> weightHistory; // newest first

  final DateTime generatedAt;

  const AiUserContextModel({
    required this.userId,
    this.name,
    this.age,
    this.gender,
    this.heightCm,
    this.currentWeightKg,
    this.goalWeightKg,
    this.activityLevel,
    this.goalType,
    this.dietPreference,
    this.workoutFrequency,
    this.targetCalories = 0,
    this.targetProtein = 0,
    this.targetCarbs = 0,
    this.targetFat = 0,
    this.dailyWaterMl = 0,
    this.weeklyPaceKg,
    required this.today,
    this.caloriesConsumedToday = 0,
    this.proteinToday = 0,
    this.carbsToday = 0,
    this.fatToday = 0,
    this.waterTodayMl = 0,
    this.calorieTotalsByDate = const {},
    this.waterTotalsByDate = const {},
    this.recentMeals = const [],
    this.weightHistory = const [],
    required this.generatedAt,
  });

  /// Safe placeholder used when the context fetch fails entirely, so the coach
  /// can still answer instead of throwing at the user.
  factory AiUserContextModel.empty(String userId, {DateTime? now}) {
    final stamp = now ?? DateTime.now();
    return AiUserContextModel(
      userId: userId,
      today: DateTime(stamp.year, stamp.month, stamp.day),
      generatedAt: stamp,
    );
  }

  /// `yyyy-MM-dd` key used by the `meals` / `water_intake` / `weight_entries`
  /// date columns.
  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  // ==================== Derived values ====================

  String get todayKey => dateKey(today);

  bool get hasProfile => heightCm != null || age != null || gender != null;

  bool get hasGoalTargets => targetCalories > 0 || dailyWaterMl > 0;

  /// Positive when calories are still available, negative when over target.
  int get calorieDelta =>
      targetCalories > 0 ? targetCalories - caloriesConsumedToday : 0;

  int get remainingCalories => calorieDelta > 0 ? calorieDelta : 0;

  int get caloriesOverTarget => calorieDelta < 0 ? -calorieDelta : 0;

  double get calorieProgress => _ratio(caloriesConsumedToday, targetCalories);

  double get proteinProgress => _ratio(proteinToday, targetProtein);

  double get carbsProgress => _ratio(carbsToday, targetCarbs);

  double get fatProgress => _ratio(fatToday, targetFat);

  double get waterProgress => _ratio(waterTodayMl, dailyWaterMl);

  /// Number of the fetched days that actually have a meal logged.
  int get loggedDaysLast7 =>
      calorieTotalsByDate.values.where((value) => value > 0).length;

  int get totalCaloriesLast7 =>
      calorieTotalsByDate.values.fold(0, (sum, value) => sum + value);

  /// Average over the days in the window (including days without entries when
  /// the window is shorter than the history, so it never flatters the user).
  int get averageCaloriesLast7 => calorieTotalsByDate.isEmpty
      ? 0
      : (totalCaloriesLast7 / calorieTotalsByDate.length).round();

  int get averageWaterLast7 => waterTotalsByDate.isEmpty
      ? 0
      : (waterTotalsByDate.values.fold(0, (sum, value) => sum + value) /
              waterTotalsByDate.length)
          .round();

  double? get latestWeightKg =>
      weightHistory.isEmpty ? null : weightHistory.first.weightKg;

  DateTime? get latestWeightDate =>
      weightHistory.isEmpty ? null : weightHistory.first.date;

  /// Change across the fetched window (latest minus oldest). Negative = loss.
  double? get weightChangeKg {
    if (weightHistory.length < 2) return null;
    final latest = weightHistory.first.weightKg;
    final oldest = weightHistory.last.weightKg;
    return double.parse((latest - oldest).toStringAsFixed(1));
  }

  /// Human readable direction of the weight trend.
  String get weightTrendLabel {
    final change = weightChangeKg;
    if (change == null) return 'not enough entries to show a trend';
    if (change.abs() < 0.1) return 'holding steady';
    return change < 0
        ? 'down ${change.abs().toStringAsFixed(1)} kg'
        : 'up ${change.abs().toStringAsFixed(1)} kg';
  }

  /// Most frequently logged foods across the fetched history (name + count).
  List<MapEntry<String, int>> get mostLoggedFoods {
    final counts = <String, int>{};
    for (final meal in recentMeals) {
      for (final item in meal.items) {
        final key = item.name.trim();
        if (key.isEmpty) continue;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  /// Compact, human-readable grounding block injected into the Gemini prompt.
  ///
  /// Every line is derived from rows this user owns; missing data is stated
  /// explicitly (`nothing logged yet`, `No weight entries yet`) so the model
  /// never has to guess or invent numbers.
  String toPromptBlock() {
    final buffer = StringBuffer();

    buffer.writeln('USER PROFILE');
    final identity = <String>[
      if (name != null && name!.trim().isNotEmpty) 'Name: ${name!.trim()}',
      if (age != null) 'Age: $age',
      if (gender != null) 'Gender: $gender',
      if (heightCm != null) 'Height: ${heightCm!.toStringAsFixed(1)} cm',
    ];
    buffer.writeln(
        identity.isEmpty ? '- Not provided yet' : '- ${identity.join(' | ')}');

    final body = <String>[
      if (currentWeightKg != null)
        'Current weight: ${currentWeightKg!.toStringAsFixed(1)} kg',
      if (goalWeightKg != null)
        'Goal weight: ${goalWeightKg!.toStringAsFixed(1)} kg',
      if (activityLevel != null) 'Activity level: $activityLevel',
      if (goalType != null) 'Goal: $goalType',
      if (dietPreference != null) 'Diet preference: $dietPreference',
      if (workoutFrequency != null) 'Workouts per week: $workoutFrequency',
      if (weeklyPaceKg != null)
        'Target pace: ${weeklyPaceKg!.toStringAsFixed(2)} kg/week',
    ];
    buffer.writeln(
        body.isEmpty ? '- No body metrics on file' : '- ${body.join(' | ')}');
    buffer.writeln();

    buffer.writeln('DAILY TARGETS');
    buffer.writeln(targetCalories > 0
        ? '- Calories: $targetCalories kcal | Protein: ${_g(targetProtein)} g '
            '| Carbs: ${_g(targetCarbs)} g | Fat: ${_g(targetFat)} g'
        : '- Calorie and macro targets are not calculated yet');
    buffer.writeln(dailyWaterMl > 0
        ? '- Water: $dailyWaterMl ml'
        : '- Water target is not set');
    buffer.writeln();

    buffer.writeln('TODAY ($todayKey)');
    final targetLabel =
        targetCalories > 0 ? '$targetCalories kcal' : 'no target set';
    buffer.writeln('- Calories: $caloriesConsumedToday kcal of $targetLabel '
        '(${_balanceLabel()})');
    buffer.writeln('- Macros eaten: protein ${_g(proteinToday)} g, '
        'carbs ${_g(carbsToday)} g, fat ${_g(fatToday)} g');
    buffer.writeln(dailyWaterMl > 0
        ? '- Water: $waterTodayMl ml of $dailyWaterMl ml '
            '(${(waterProgress * 100).round()}%)'
        : '- Water: $waterTodayMl ml logged');
    final mealsToday = recentMeals
        .where((meal) => dateKey(meal.date) == todayKey)
        .toList()
      ..sort((a, b) => a.mealType.compareTo(b.mealType));
    if (mealsToday.isEmpty) {
      buffer.writeln('- Meals: nothing logged yet');
    } else {
      buffer.writeln('- Meals:');
      for (final meal in mealsToday) {
        final items = meal.items.isEmpty
            ? 'no item detail'
            : meal.items
                .map((item) => '${item.name} (${item.calories} kcal)')
                .join(', ');
        buffer.writeln(
            '  * ${meal.mealType}: ${meal.computedCalories} kcal - $items');
      }
    }
    buffer.writeln();

    buffer.writeln('LAST ${calorieTotalsByDate.length} DAYS');
    if (calorieTotalsByDate.isEmpty) {
      buffer.writeln('- No meals logged');
    } else {
      buffer.writeln(
          '- Calories by day: ${_mapSummary(calorieTotalsByDate, 'kcal')}');
      buffer.writeln('- Average: $averageCaloriesLast7 kcal/day across '
          '$loggedDaysLast7 logged day(s)');
    }
    if (waterTotalsByDate.isEmpty) {
      buffer.writeln('- No water logged');
    } else {
      buffer.writeln('- Water average: $averageWaterLast7 ml/day');
    }
    final foods = mostLoggedFoods;
    if (foods.isNotEmpty) {
      buffer.writeln('- Most logged foods: '
          '${foods.map((entry) => '${entry.key} x${entry.value}').join(', ')}');
    }
    buffer.writeln();

    buffer.writeln('WEIGHT (${weightHistory.length} recent entries)');
    if (weightHistory.isEmpty) {
      buffer.writeln('- No weight entries yet');
    } else {
      buffer.writeln('- Latest: ${latestWeightKg!.toStringAsFixed(1)} kg on '
          '${dateKey(latestWeightDate!)}');
      buffer.writeln('- Trend: $weightTrendLabel');
      final entries = weightHistory
          .take(10)
          .map((point) =>
              '${dateKey(point.date)}: ${point.weightKg.toStringAsFixed(1)} kg')
          .join(', ');
      buffer.writeln('- Entries: $entries');
    }

    return buffer.toString().trim();
  }

  /// Structured payload of the scalar context (used for logging/debugging the
  /// context layer). History collections are intentionally not serialized -
  /// they are rebuilt from Supabase on every fetch.
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        if (name != null) 'name': name,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (heightCm != null) 'height_cm': heightCm,
        if (currentWeightKg != null) 'current_weight_kg': currentWeightKg,
        if (goalWeightKg != null) 'goal_weight_kg': goalWeightKg,
        if (activityLevel != null) 'activity_level': activityLevel,
        if (goalType != null) 'goal_type': goalType,
        if (dietPreference != null) 'diet_preference': dietPreference,
        if (workoutFrequency != null) 'workout_frequency': workoutFrequency,
        'target_calories': targetCalories,
        'target_protein': targetProtein,
        'target_carbs': targetCarbs,
        'target_fat': targetFat,
        'daily_water_ml': dailyWaterMl,
        if (weeklyPaceKg != null) 'weekly_pace_kg': weeklyPaceKg,
        'today': todayKey,
        'calories_consumed_today': caloriesConsumedToday,
        'protein_today': proteinToday,
        'carbs_today': carbsToday,
        'fat_today': fatToday,
        'water_today_ml': waterTodayMl,
        'generated_at': generatedAt.toIso8601String(),
      };

  /// Rebuilds the scalar part of the context (see [toJson]).
  factory AiUserContextModel.fromJson(Map<String, dynamic> json) =>
      AiUserContextModel(
        userId: json['user_id']?.toString() ?? '',
        name: json['name'] as String?,
        age: _toNullableInt(json['age']),
        gender: json['gender'] as String?,
        heightCm: _toNullableDouble(json['height_cm']),
        currentWeightKg: _toNullableDouble(json['current_weight_kg']),
        goalWeightKg: _toNullableDouble(json['goal_weight_kg']),
        activityLevel: json['activity_level'] as String?,
        goalType: json['goal_type'] as String?,
        dietPreference: json['diet_preference'] as String?,
        workoutFrequency: _toNullableInt(json['workout_frequency']),
        targetCalories: _toInt(json['target_calories']),
        targetProtein: _toDouble(json['target_protein']),
        targetCarbs: _toDouble(json['target_carbs']),
        targetFat: _toDouble(json['target_fat']),
        dailyWaterMl: _toInt(json['daily_water_ml']),
        weeklyPaceKg: _toNullableDouble(json['weekly_pace_kg']),
        today:
            DateTime.tryParse(json['today']?.toString() ?? '') ?? DateTime.now(),
        caloriesConsumedToday: _toInt(json['calories_consumed_today']),
        proteinToday: _toDouble(json['protein_today']),
        carbsToday: _toDouble(json['carbs_today']),
        fatToday: _toDouble(json['fat_today']),
        waterTodayMl: _toInt(json['water_today_ml']),
        generatedAt:
            DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
                DateTime.now(),
      );

  String _balanceLabel() {
    if (targetCalories <= 0) return 'no calorie target set';
    if (calorieDelta >= 0) return '$remainingCalories kcal left';
    return '$caloriesOverTarget kcal over target';
  }

  /// Renders `120.0` as `120` and `62.5` as `62.5`.
  static String _g(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  static String _mapSummary(Map<String, int> values, String unit) =>
      values.entries.map((entry) => '${entry.key}: ${entry.value} $unit').join(
          ', ');

  static double _ratio(num value, num target) {
    if (target <= 0) return 0;
    final ratio = value / target;
    if (ratio.isNaN || ratio.isInfinite) return 0;
    return ratio;
  }
}

  return 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.round();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
  }
  return 0;
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}
