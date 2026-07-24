import '../entities/meal_entity.dart';

abstract class MealRepository {
  Future<List<MealEntity>> getMealsByDate(String userId, DateTime date);
  Future<MealEntity> addMeal(MealEntity meal, List<Map<String, dynamic>> items);
  Future<void> updateMeal(String mealId, Map<String, dynamic> data);
  Future<void> deleteMeal(String mealId);
}