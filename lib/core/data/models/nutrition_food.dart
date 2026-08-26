/// Nutrition values per 100 g returned by the real food APIs (USDA / OpenFoodFacts).
class NutritionFood {
  final String source; // 'USDA' | 'OpenFoodFacts' | 'Local'
  final String externalId;
  final String name;
  final String? brand;

  final double energyKcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodiumMg;
  final double potassiumMg;
  final double calciumMg;
  final double ironMg;
  final double vitaminCMg;

  const NutritionFood({
    required this.source,
    required this.externalId,
    required this.name,
    this.brand,
    this.energyKcal = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodiumMg = 0,
    this.potassiumMg = 0,
    this.calciumMg = 0,
    this.ironMg = 0,
    this.vitaminCMg = 0,
  });
}