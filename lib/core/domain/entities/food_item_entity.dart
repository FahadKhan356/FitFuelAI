class FoodItemEntity {
  final String id;
  final String name;
  final String? brand;
  final String source;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double potassiumMg;
  final double calciumMg;
  final double ironMg;
  final double vitaminCMg;
  final double saturatedFatG;
  final double servingSize;
  final String servingUnit;
  final String? barcode;
  final String? externalId;
  final String? imageUrl;

  const FoodItemEntity({
    required this.id,
    required this.name,
    this.brand,
    this.source = 'USDA',
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.potassiumMg = 0,
    this.calciumMg = 0,
    this.ironMg = 0,
    this.vitaminCMg = 0,
    this.saturatedFatG = 0,
    this.servingSize = 100,
    this.servingUnit = 'g',
    this.barcode,
    this.externalId,
    this.imageUrl,
  });
}