import '../../domain/entities/food_item_entity.dart';
import '../../domain/repositories/food_search_repository.dart';
import '../datasources/supabase_remote_datasource.dart';

class FoodSearchRepositoryImpl implements FoodSearchRepository {
  final SupabaseRemoteDataSource _dataSource;

  FoodSearchRepositoryImpl(this._dataSource);

  @override
  Future<List<FoodItemEntity>> searchFoodItems(String query) async {
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
      servingSize: m.servingSize,
      servingUnit: m.servingUnit,
      barcode: m.barcode,
      externalId: m.externalId,
    )).toList();
  }
}