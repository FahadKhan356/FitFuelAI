/// Stateless utility class for computing fitness/nutrition metrics.
///
/// Uses the Mifflin-St Jeor equation for BMR, standard activity multipliers
/// for TDEE, goal/pace based calorie adjustment, macro split, and water intake.
class FitnessCalculator {
  FitnessCalculator._();

  // ─── Activity Multipliers ───
  static const Map<String, double> activityMultipliers = {
    'sedentary': 1.2,
    'lightly_active': 1.375,
    'moderately_active': 1.55,
    'very_active': 1.725,
  };

  // ─── Constants ───
  static const int minCaloriesForLoss = 1200;
  static const double caloriesPerKg = 7700; // ~7700 kcal per kg fat, adjusted
  static const double proteinGramsPerKg = 2.0;
  static const double proteinCaloriesPerGram = 4;
  static const double carbCaloriesPerGram = 4;
  static const double fatCaloriesPerGram = 9;
  static const double fatCalorieRatio = 0.25; // 25% fat
  static const double waterMlPerKg = 35;
  static const int veryActiveExtraWaterMl = 500;

  /// Baseline Metabolic Rate (Mifflin-St Jeor)
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    if (gender.toLowerCase() == 'male') {
      return base + 5;
    }
    return base - 161;
  }

  /// Total Daily Energy Expenditure
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    final multiplier = activityMultipliers[activityLevel] ?? 1.2;
    return bmr * multiplier;
  }

  /// Target daily calories based on goal type and weekly pace.
  ///
  /// - [weeklyPaceKg] is the desired loss/gain per week (e.g. 0.5).
  /// - `weight_loss`: subtracts `weeklyPaceKg * 1100 / 7`, capped at 1200 kcal.
  /// - `weight_gain`: adds `weeklyPaceKg * 1100 / 7`.
  /// - `maintain` / `cutting`: returns TDEE unchanged.
  static int calculateTargetCalories({
    required double tdee,
    required String goalType,
    double weeklyPaceKg = 0.5,
  }) {
    final adjustment = (weeklyPaceKg * caloriesPerKg) / 7;

    switch (goalType) {
      case 'weight_loss':
        final target = tdee - adjustment;
        return target.round().clamp(minCaloriesForLoss, 0x7FFFFFFF);
      case 'weight_gain':
        return (tdee + adjustment).round();
      case 'maintain':
      case 'cutting':
      default:
        return tdee.round();
    }
  }

  /// Target protein grams per day: 2.0g per kg of current body weight.
  static double calculateProtein({required double weightKg}) {
    return double.parse((weightKg * proteinGramsPerKg).toStringAsFixed(1));
  }

  /// Target fat grams per day: 25% of total target calories.
  static double calculateFat({required int targetCalories}) {
    return double.parse(
      ((targetCalories * fatCalorieRatio) / fatCaloriesPerGram).toStringAsFixed(1),
    );
  }

  /// Target carb grams per day: remaining calories after protein & fat.
  static double calculateCarbs({
    required int targetCalories,
    required double targetProtein,
    required double targetFat,
  }) {
    final proteinCalories = targetProtein * proteinCaloriesPerGram;
    final fatCalories = targetFat * fatCaloriesPerGram;
    final remaining = targetCalories - proteinCalories - fatCalories;
    return double.parse((remaining / carbCaloriesPerGram).toStringAsFixed(1));
  }

  /// Daily water intake: 35ml per kg + 500ml if `very_active`.
  static int calculateDailyWater({
    required double weightKg,
    required String activityLevel,
  }) {
    var water = weightKg * waterMlPerKg;
    if (activityLevel == 'very_active') {
      water += veryActiveExtraWaterMl;
    }
    return water.round();
  }

  /// One-stop method to compute all targets from profile + goal inputs.
  static Map<String, dynamic> calculateAllTargets({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String activityLevel,
    required String goalType,
    double weeklyPaceKg = 0.5,
  }) {
    final bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );

    final tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel);

    final targetCalories = calculateTargetCalories(
      tdee: tdee,
      goalType: goalType,
      weeklyPaceKg: weeklyPaceKg,
    );

    final targetProtein = calculateProtein(weightKg: weightKg);
    final targetFat = calculateFat(targetCalories: targetCalories);
    final targetCarbs = calculateCarbs(
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetFat: targetFat,
    );
    final dailyWaterMl = calculateDailyWater(
      weightKg: weightKg,
      activityLevel: activityLevel,
    );

    return {
      'bmr': double.parse(bmr.toStringAsFixed(1)),
      'tdee': double.parse(tdee.toStringAsFixed(1)),
      'target_calories': targetCalories,
      'target_protein': targetProtein,
      'target_carbs': targetCarbs,
      'target_fat': targetFat,
      'daily_water_ml': dailyWaterMl,
    };
  }
}