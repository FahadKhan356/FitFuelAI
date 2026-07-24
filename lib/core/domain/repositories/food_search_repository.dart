import '../entities/food_item_entity.dart';

abstract class FoodSearchRepository {
  Future<List<FoodItemEntity>> searchFoodItems(String query);
}