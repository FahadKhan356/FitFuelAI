import '../../domain/entities/barcode_product_entity.dart';
import '../../domain/repositories/barcode_repository.dart';
import '../../../../features/food_search/data/datasources/nutrition_api_datasource.dart';
import '../datasources/supabase_remote_datasource.dart';

class BarcodeRepositoryImpl implements BarcodeRepository {
  final SupabaseRemoteDataSource _dataSource;
  final NutritionApiDataSource _nutritionApi;

  BarcodeRepositoryImpl(this._dataSource,
      [NutritionApiDataSource? nutritionApi])
      : _nutritionApi = nutritionApi ?? NutritionApiDataSource();

  @override
  Future<BarcodeProductEntity?> getProductByBarcode(String barcode) async {
    // 1. Try the local Supabase cache first.
    final cached = await _dataSource.getProductByBarcode(barcode);
    if (cached != null) {
      return BarcodeProductEntity(
        id: cached.id,
        barcode: cached.barcode,
        productName: cached.productName,
        brand: cached.brand,
        calories: cached.calories,
        nutritionData: cached.nutritionData,
        source: cached.source,
        createdAt: cached.createdAt,
      );
    }

    // 2. Fall back to a live OpenFoodFacts lookup and cache the result.
    final live = await _nutritionApi.getProductByBarcode(barcode);
    if (live == null) return null;

    final entity = BarcodeProductEntity(
      id: barcode,
      barcode: barcode,
      productName: live.name,
      brand: live.brand,
      calories: live.energyKcal > 0 ? live.energyKcal.round() : null,
      nutritionData: {
        'calories': live.energyKcal,
        'protein': live.protein,
        'carbs': live.carbs,
        'fat': live.fat,
        'fiber': live.fiber,
        'sugar': live.sugar,
        'sodium': live.sodiumMg,
        'serving_size': 100,
        'serving_unit': 'g',
      },
      source: live.source,
    );

    try {
      await saveBarcodeProduct(entity);
    } catch (_) {
      // Caching failure is non-fatal.
    }
    return entity;
  }

  @override
  Future<void> saveBarcodeProduct(BarcodeProductEntity product) async {
    await _dataSource.saveBarcodeProduct({
      'barcode': product.barcode,
      'product_name': product.productName,
      if (product.brand != null) 'brand': product.brand,
      if (product.calories != null) 'calories': product.calories,
      if (product.nutritionData != null) 'nutrition_data': product.nutritionData,
      'source': product.source,
    });
  }
}