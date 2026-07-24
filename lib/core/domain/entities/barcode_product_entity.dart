class BarcodeProductEntity {
  final String id;
  final String barcode;
  final String productName;
  final String? brand;
  final int? calories;
  final Map<String, dynamic>? nutritionData;
  final String source;
  final DateTime? createdAt;

  const BarcodeProductEntity({
    required this.id,
    required this.barcode,
    required this.productName,
    this.brand,
    this.calories,
    this.nutritionData,
    this.source = 'OpenFoodFacts',
    this.createdAt,
  });
}