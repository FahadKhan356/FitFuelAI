class BarcodeModel {
  final String id;
  final String barcode;
  final String productName;
  final String? brand;
  final int? calories;
  final Map<String, dynamic>? nutritionData;
  final String source;
  final DateTime? createdAt;

  const BarcodeModel({
    required this.id,
    required this.barcode,
    required this.productName,
    this.brand,
    this.calories,
    this.nutritionData,
    this.source = 'OpenFoodFacts',
    this.createdAt,
  });

  factory BarcodeModel.fromJson(Map<String, dynamic> json) {
    return BarcodeModel(
      id: json['id'] as String,
      barcode: json['barcode'] as String,
      productName: json['product_name'] as String,
      brand: json['brand'] as String?,
      calories: json['calories'] as int?,
      nutritionData: json['nutrition_data'] as Map<String, dynamic>?,
      source: json['source'] as String? ?? 'OpenFoodFacts',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'product_name': productName,
      if (brand != null) 'brand': brand,
      if (calories != null) 'calories': calories,
      if (nutritionData != null) 'nutrition_data': nutritionData,
      'source': source,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}