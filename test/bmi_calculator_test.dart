import 'package:fitfuel_ai/core/utils/bmi_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BmiCalculator.calculateBmi', () {
    test('computes the standard metric BMI (kg/m²)', () {
      // 70 kg @ 1.75 m -> 70 / (1.75 * 1.75) = 22.9
      expect(BmiCalculator.calculateBmi(weightKg: 70, heightCm: 175), 22.9);
      // 53 kg @ 1.72 m -> 53 / (1.72 * 1.72) = 17.9
      expect(BmiCalculator.calculateBmi(weightKg: 53, heightCm: 172), 17.9);
    });

    test('rejects non-positive inputs instead of returning NaN', () {
      expect(
        () => BmiCalculator.calculateBmi(weightKg: 0, heightCm: 175),
        throwsArgumentError,
      );
      expect(
        () => BmiCalculator.calculateBmi(weightKg: 70, heightCm: 0),
        throwsArgumentError,
      );
    });
  });

  group('BmiCalculator.classify (WHO granular)', () {
    test('classifies every band including the sub-gradations', () {
      expect(BmiCalculator.classify(15.9), BmiCategory.severeUnderweight);
      expect(BmiCalculator.classify(16.4), BmiCategory.moderateUnderweight);
      expect(BmiCalculator.classify(17.9), BmiCategory.mildUnderweight);
      expect(BmiCalculator.classify(22.0), BmiCategory.normal);
      expect(BmiCalculator.classify(27.5), BmiCategory.overweight);
      expect(BmiCalculator.classify(32.4), BmiCategory.obeseClassI);
      expect(BmiCalculator.classify(37.9), BmiCategory.obeseClassII);
      expect(BmiCalculator.classify(41.0), BmiCategory.obeseClassIII);
    });

    test('boundary values land on the correct side', () {
      expect(BmiCalculator.classify(18.5), BmiCategory.normal);
      expect(BmiCalculator.classify(25.0), BmiCategory.overweight);
      expect(BmiCalculator.classify(30.0), BmiCategory.obeseClassI);
    });
  });

  group('BmiCalculator.bmiPrime', () {
    test('is BMI / 25 (ratio to healthy upper bound)', () {
      expect(BmiCalculator.bmiPrime(25.0), 1.0);
      expect(BmiCalculator.bmiPrime(22.5), 0.9);
      expect(BmiCalculator.bmiPrime(30.0), 1.2);
    });
  });

  group('BmiCalculator.healthyWeightRange', () {
    test('returns WHO 18.5–24.9 window for a given height', () {
      // 1.75 m: 18.5 * 3.0625 = 56.7 .. 24.9 * 3.0625 = 76.3
      final range = BmiCalculator.healthyWeightRange(heightCm: 175);
      expect(range.min, 56.7);
      expect(range.max, 76.3);
    });
  });

  group('BmiCalculator.calculate (end-to-end)', () {
    test('returns a full result with prime, range and goal delta', () {
      final r = BmiCalculator.calculate(weightKg: 72.4, heightCm: 175);
      expect(r.bmi, 23.6);
      expect(r.category, BmiCategory.normal);
      expect(r.bmiPrime, 0.94); // computed from the rounded BMI (23.6 / 25)
      expect(r.healthyWeightMinKg, 56.7);
      expect(r.healthyWeightMaxKg, 76.3);
      expect(r.deltaToHealthyKg, 0.0);
    });

    test('gives a positive loss delta when overweight', () {
      final r = BmiCalculator.calculate(weightKg: 90, heightCm: 175);
      expect(r.category, BmiCategory.overweight);
      expect(r.bmi, 29.4);
      expect(r.deltaToHealthyKg, greaterThan(0));
    });

    test('gives a negative (gain) delta when underweight', () {
      final r = BmiCalculator.calculate(weightKg: 50, heightCm: 175);
      // 50 / 1.75² = 16.3 → moderate thinness (16.0–16.9)
      expect(r.category, BmiCategory.moderateUnderweight);
      expect(r.deltaToHealthyKg, lessThan(0));
    });
  });
}