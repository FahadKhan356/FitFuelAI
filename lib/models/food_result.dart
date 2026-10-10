// lib/models/food_result.dart

class FoodResult {
  const FoodResult({
    required this.foodName,
    required this.servingQuantity,
    required this.servingUnit,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.source,
    this.cuisineType,
    this.sodiumMg = 0,
    this.potassiumMg = 0,
    this.fiberG = 0,
    this.sugarG = 0,
    this.accuracyWarning = false,
  });

  factory FoodResult.fromSupabase(Map<String, dynamic> row) => FoodResult(
        foodName: row['food_name'] as String,
        servingQuantity: (row['serving_quantity'] as num).toDouble(),
        servingUnit: row['serving_unit'] as String,
        calories: (row['calories'] as num).toDouble(),
        proteinG: (row['protein_g'] as num).toDouble(),
        carbsG: (row['carbs_g'] as num).toDouble(),
        fatG: (row['fat_g'] as num).toDouble(),
        source: 'supabase_cache',
        cuisineType: row['cuisine_type'] as String?,
        sodiumMg: (row['sodium_mg'] as num? ?? 0).toDouble(),
        potassiumMg: (row['potassium_mg'] as num? ?? 0).toDouble(),
        fiberG: (row['fiber_g'] as num? ?? 0).toDouble(),
        sugarG: (row['sugar_g'] as num? ?? 0).toDouble(),
        accuracyWarning: row['accuracy_warning'] as bool? ?? false,
      );

  final String foodName;
  final String? cuisineType;
  final double servingQuantity; // always 100 (g/ml) or 1 (piece/spoon)
  final String servingUnit; // 'grams' | 'ml' | 'piece' | 'tablespoon'
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double sodiumMg;
  final double potassiumMg;
  final double fiberG;
  final double sugarG;
  final String source; // 'supabase_cache' | 'fatsecret_api' | 'gemini_ai'
  final bool accuracyWarning; // true = gemini data, show amber badge in UI

  // ── Scale to any user-logged quantity ──────────────────────────────
  // servingQuantity is always 100g or 1 piece baseline
  // userQuantity is what user actually logs (e.g. 250g)
  FoodResult scaleToQuantity(double userQuantity) {
    final factor = servingQuantity == 0 ? 1.0 : (userQuantity / servingQuantity);
    return FoodResult(
      foodName: foodName,
      cuisineType: cuisineType,
      servingQuantity: userQuantity,
      servingUnit: servingUnit,
      calories: _r(calories * factor),
      proteinG: _r(proteinG * factor),
      carbsG: _r(carbsG * factor),
      fatG: _r(fatG * factor),
      sodiumMg: _r(sodiumMg * factor),
      potassiumMg: _r(potassiumMg * factor),
      fiberG: _r(fiberG * factor),
      sugarG: _r(sugarG * factor),
      source: source,
      accuracyWarning: accuracyWarning,
    );
  }

  double _r(double v) => double.parse(v.toStringAsFixed(2));

  Map<String, dynamic> toSupabaseMap(String searchKey, String countryCode) => {
        'search_key': searchKey,
        'country_code': countryCode,
        'food_name': foodName,
        'cuisine_type': cuisineType,
        'serving_quantity': servingQuantity,
        'serving_unit': servingUnit,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
        'sodium_mg': sodiumMg,
        'potassium_mg': potassiumMg,
        'fiber_g': fiberG,
        'sugar_g': sugarG,
        'source': source,
        'accuracy_warning': accuracyWarning,
      };
}
