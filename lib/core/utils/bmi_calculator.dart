/// World Health Organization (WHO) BMI classification for adults.
///
/// Real fitness/health apps (MyFitnessPal, Lose It!, Apple Health, etc.)
/// don't just compute `weight / height²` — they also surface the granular
/// WHO clinical categories, a **BMI Prime** (ratio to the top of the normal
/// band), the **healthy weight range** for the user's height, and the number
/// of kg to reach that healthy band. This class centralises that logic so it
/// is pure (no Flutter UI types), unit-testable, and shared wherever needed.
enum BmiCategory {
  severeUnderweight,
  moderateUnderweight,
  mildUnderweight,
  normal,
  overweight,
  obeseClassI,
  obeseClassII,
  obeseClassIII,
}

extension BmiCategoryInfo on BmiCategory {
  /// Short, user-facing label (what shows on the badge / scale).
  String get label => switch (this) {
        BmiCategory.severeUnderweight ||
        BmiCategory.moderateUnderweight ||
        BmiCategory.mildUnderweight =>
          'Underweight',
        BmiCategory.normal => 'Normal',
        BmiCategory.overweight => 'Overweight',
        BmiCategory.obeseClassI ||
        BmiCategory.obeseClassII ||
        BmiCategory.obeseClassIII =>
          'Obese',
      };

  /// Full, clinical WHO diagnostic name.
  String get diagnostic => switch (this) {
        BmiCategory.severeUnderweight => 'Severe thinness',
        BmiCategory.moderateUnderweight => 'Moderate thinness',
        BmiCategory.mildUnderweight => 'Mild thinness',
        BmiCategory.normal => 'Normal weight',
        BmiCategory.overweight => 'Overweight',
        BmiCategory.obeseClassI => 'Obese — Class I',
        BmiCategory.obeseClassII => 'Obese — Class II',
        BmiCategory.obeseClassIII => 'Obese — Class III',
      };

  /// Concise, actionable follow-up shown under the result (like real apps do).
  String get advice => switch (this) {
        BmiCategory.severeUnderweight ||
        BmiCategory.moderateUnderweight ||
        BmiCategory.mildUnderweight =>
          'You are below the healthy range. A gradual calorie surplus with '
              'strength training can help you gain lean mass safely.',
        BmiCategory.normal =>
          'You are in a healthy range. Keep a balanced diet and stay active to '
              'maintain it.',
        BmiCategory.overweight =>
          'You are above the healthy range. A modest calorie deficit of '
              '300–500 kcal/day is a sustainable first step.',
        BmiCategory.obeseClassI ||
        BmiCategory.obeseClassII ||
        BmiCategory.obeseClassIII =>
          'A structured plan is recommended. Consider consulting a healthcare '
              'professional to set safe, sustainable targets.',
      };

  /// Inclusive lower BMI bound of this category.
  double get minBmi => switch (this) {
        BmiCategory.severeUnderweight => double.negativeInfinity,
        BmiCategory.moderateUnderweight => 16.0,
        BmiCategory.mildUnderweight => 17.0,
        BmiCategory.normal => 18.5,
        BmiCategory.overweight => 25.0,
        BmiCategory.obeseClassI => 30.0,
        BmiCategory.obeseClassII => 35.0,
        BmiCategory.obeseClassIII => 40.0,
      };

  /// Exclusive upper bound of this category.
  double get maxBmi => switch (this) {
        BmiCategory.severeUnderweight => 16.0,
        BmiCategory.moderateUnderweight => 17.0,
        BmiCategory.mildUnderweight => 18.5,
        BmiCategory.normal => 25.0,
        BmiCategory.overweight => 30.0,
        BmiCategory.obeseClassI => 35.0,
        BmiCategory.obeseClassII => 40.0,
        BmiCategory.obeseClassIII => double.infinity,
      };
}

/// The outcome of a single BMI calculation.
class BmiResult {
  final double bmi;
  final BmiCategory category;

  /// BMI / 25. A value of 1.0 is exactly the boundary of the healthy band.
  final double bmiPrime;

  /// Healthy weight band (kg) for this person's height (WHO: 18.5 – 24.9 BMI).
  final double healthyWeightMinKg;
  final double healthyWeightMaxKg;

  /// Kilograms to the nearest healthy boundary. Negative when the user needs
  /// to _gain_ weight, positive when they need to _lose_ weight, zero when
  /// already inside the healthy band.
  final double deltaToHealthyKg;

  const BmiResult({
    required this.bmi,
    required this.category,
    required this.bmiPrime,
    required this.healthyWeightMinKg,
    required this.healthyWeightMaxKg,
    required this.deltaToHealthyKg,
  });
}

class BmiCalculator {
  BmiCalculator._();

  /// Unit-safe, health-checked BMI. Accepts height in [heightCm]
  /// (centimetres) — the unit real apps actually collect — and rejects
  /// invalid inputs instead of silently returning NaN.
  static double calculateBmi({
    required double weightKg,
    required double heightCm,
  }) {
    if (weightKg <= 0 || heightCm <= 0) {
      throw ArgumentError.value(
        (weightKg, heightCm),
        '(weightKg, heightCm)',
        'Weight and height must be positive.',
      );
    }
    final heightM = heightCm / 100.0;
    return _round1(weightKg / (heightM * heightM));
  }

  /// The ratio of the user's BMI to the upper limit of the normal band (25).
  /// Widely used by clinicians and fitness apps as an easy-to-read fraction.
  static double bmiPrime(double bmi) => _round2(bmi / 25.0);

  /// Classifies a BMI into the granular WHO adult category.
  static BmiCategory classify(double bmi) {
    if (bmi < 16.0) return BmiCategory.severeUnderweight;
    if (bmi < 17.0) return BmiCategory.moderateUnderweight;
    if (bmi < 18.5) return BmiCategory.mildUnderweight;
    if (bmi < 25.0) return BmiCategory.normal;
    if (bmi < 30.0) return BmiCategory.overweight;
    if (bmi < 35.0) return BmiCategory.obeseClassI;
    if (bmi < 40.0) return BmiCategory.obeseClassII;
    return BmiCategory.obeseClassIII;
  }

  /// Healthy body-weight range in kg for a given height (cm),
  /// per the WHO 18.5 – 24.9 normal window.
  static ({double min, double max}) healthyWeightRange({
    required double heightCm,
  }) {
    if (heightCm <= 0) {
      throw ArgumentError.value(heightCm, 'heightCm', 'Must be positive.');
    }
    final heightM = heightCm / 100.0;
    return (
      min: _round1(18.5 * heightM * heightM),
      max: _round1(24.9 * heightM * heightM),
    );
  }

  /// One-stop method returning everything the UI needs to display.
  static BmiResult calculate({
    required double weightKg,
    required double heightCm,
  }) {
    final bmi = calculateBmi(weightKg: weightKg, heightCm: heightCm);
    final range = healthyWeightRange(heightCm: heightCm);
    final category = classify(bmi);

    final double delta;
    if (bmi < 18.5) {
      // Below the band → needs to _gain_: negative delta = amount to gain.
      delta = weightKg - range.min;
    } else if (bmi > 24.9) {
      // Above the band → needs to _lose_: positive delta = amount to lose.
      delta = weightKg - range.max;
    } else {
      delta = 0.0;
    }

    return BmiResult(
      bmi: bmi,
      category: category,
      bmiPrime: bmiPrime(bmi),
      healthyWeightMinKg: range.min,
      healthyWeightMaxKg: range.max,
      deltaToHealthyKg: _round1(delta),
    );
  }

  static double _round1(double v) => (v * 10).roundToDouble() / 10;
  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}