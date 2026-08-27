import '../../../features/food_search/data/datasources/nutrition_api_datasource.dart';
import '../../domain/entities/food_item_entity.dart';
import '../../domain/repositories/food_search_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class FoodSearchRepositoryImpl implements FoodSearchRepository {
  final SupabaseRemoteDataSource _dataSource;
  final NutritionApiDataSource _nutritionApi;

  FoodSearchRepositoryImpl(this._dataSource,
      [NutritionApiDataSource? nutritionApi])
      : _nutritionApi = nutritionApi ?? NutritionApiDataSource();

  @override
  Future<List<FoodItemEntity>> searchFoodItems(String query) async {
    // 1) Live triple-API search (USDA + OpenFoodFacts + CalorieNinjas) gives
    //    complete macros + micronutrients + product images.
    try {
      final live = await _nutritionApi.searchFoods(query);
      if (live.isNotEmpty) {
        return live
            .map(
              (n) => FoodItemEntity(
                id: n.externalId.isNotEmpty ? n.externalId : n.name,
                name: n.name,
                brand: n.brand,
                source: n.source,
                calories: n.energyKcal.round(),
                protein: n.protein,
                carbs: n.carbs,
                fat: n.fat,
                fiber: n.fiber,
                sugar: n.sugar,
                sodium: n.sodiumMg,
                potassiumMg: n.potassiumMg,
                calciumMg: n.calciumMg,
                ironMg: n.ironMg,
                vitaminCMg: n.vitaminCMg,
                saturatedFatG: n.saturatedFatG,
                servingSize: 100,
                servingUnit: 'g',
                externalId: n.externalId.isNotEmpty ? n.externalId : null,
                imageUrl: n.imageUrl,
              ),
            )
            .toList();
      }
    } catch (_) {
      // Fall through to the local Supabase food table below.
    }

    // 2) Fallback: locally stored food items.
    final models = await _dataSource.searchFoodItems(query);
    return models.map((m) => FoodItemEntity(
      id: m.id,
      name: m.name,
      brand: m.brand,
      source: m.source,
      calories: m.calories,
      protein: m.protein,
      carbs: m.carbs,
      fat: m.fat,
      fiber: m.fiber,
      sugar: m.sugar,
      sodium: m.sodium,
      potassiumMg: m.potassiumMg,
      calciumMg: m.calciumMg,
      ironMg: m.ironMg,
      vitaminCMg: m.vitaminCMg,
      saturatedFatG: m.saturatedFatG,
      servingSize: m.servingSize,
      servingUnit: m.servingUnit,
      barcode: m.barcode,
      externalId: m.externalId,
      imageUrl: m.imageUrl,
    )).toList();
  }
}