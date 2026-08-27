class FoodItemModel {
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

  const FoodItemModel({
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

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      source: json['source'] as String? ?? 'USDA',
      calories: json['calories'] as int,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0,
      sodium: (json['sodium'] as num?)?.toDouble() ?? 0,
      potassiumMg: (json['potassium'] as num?)?.toDouble() ?? 0,
      calciumMg: (json['calcium'] as num?)?.toDouble() ?? 0,
      ironMg: (json['iron'] as num?)?.toDouble() ?? 0,
      vitaminCMg: (json['vitamin_c'] as num?)?.toDouble() ?? 0,
      saturatedFatG: (json['saturated_fat'] as num?)?.toDouble() ?? 0,
      servingSize: (json['serving_size'] as num?)?.toDouble() ?? 100,
      servingUnit: json['serving_unit'] as String? ?? 'g',
      barcode: json['barcode'] as String?,
      externalId: json['external_id'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (brand != null) 'brand': brand,
      'source': source,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'potassium': potassiumMg,
      'calcium': calciumMg,
      'iron': ironMg,
      'vitamin_c': vitaminCMg,
      'saturated_fat': saturatedFatG,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      if (barcode != null) 'barcode': barcode,
      if (externalId != null) 'external_id': externalId,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}