import 'package:fitfuel_ai/models/food_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodResult Model Tests', () {
    const baseline = FoodResult(
      foodName: 'Chicken Biryani',
      cuisineType: 'Pakistani',
      servingQuantity: 100,
      servingUnit: 'grams',
      calories: 165,
      proteinG: 12.5,
      carbsG: 18.0,
      fatG: 4.5,
      sodiumMg: 350,
      potassiumMg: 200,
      fiberG: 1.5,
      sugarG: 0.5,
      source: 'gemini_ai',
      accuracyWarning: true,
    );

    test('scaleToQuantity() scales nutrition values proportionally', () {
      final scaled = baseline.scaleToQuantity(250);

      expect(scaled.servingQuantity, 250);
      expect(scaled.servingUnit, 'grams');
      // 165 * 2.5 = 412.5
      expect(scaled.calories, 412.5);
      // 12.5 * 2.5 = 31.25
      expect(scaled.proteinG, 31.25);
      // 18.0 * 2.5 = 45.0
      expect(scaled.carbsG, 45.0);
      // 4.5 * 2.5 = 11.25
      expect(scaled.fatG, 11.25);
      // 350 * 2.5 = 875.0
      expect(scaled.sodiumMg, 875.0);
      expect(scaled.source, 'gemini_ai');
      expect(scaled.accuracyWarning, isTrue);
    });

    test('toSupabaseMap() creates correct map payload', () {
      final map = baseline.toSupabaseMap('chicken biryani', 'PK');

      expect(map['search_key'], 'chicken biryani');
      expect(map['country_code'], 'PK');
      expect(map['food_name'], 'Chicken Biryani');
      expect(map['cuisine_type'], 'Pakistani');
      expect(map['serving_quantity'], 100);
      expect(map['serving_unit'], 'grams');
      expect(map['calories'], 165);
      expect(map['protein_g'], 12.5);
      expect(map['carbs_g'], 18.0);
      expect(map['fat_g'], 4.5);
      expect(map['sodium_mg'], 350);
      expect(map['source'], 'gemini_ai');
      expect(map['accuracy_warning'], isTrue);
    });

    test('fromSupabase() parses map correctly and sets source to supabase_cache', () {
      final row = {
        'food_name': 'Chicken Biryani',
        'cuisine_type': 'Pakistani',
        'serving_quantity': 100,
        'serving_unit': 'grams',
        'calories': 165.0,
        'protein_g': 12.5,
        'carbs_g': 18.0,
        'fat_g': 4.5,
        'sodium_mg': 350.0,
        'potassium_mg': 200.0,
        'fiber_g': 1.5,
        'sugar_g': 0.5,
        'accuracy_warning': true,
      };

      final parsed = FoodResult.fromSupabase(row);

      expect(parsed.foodName, 'Chicken Biryani');
      expect(parsed.cuisineType, 'Pakistani');
      expect(parsed.servingQuantity, 100.0);
      expect(parsed.calories, 165.0);
      expect(parsed.proteinG, 12.5);
      expect(parsed.source, 'supabase_cache');
      expect(parsed.accuracyWarning, isTrue);
    });
  });
}
