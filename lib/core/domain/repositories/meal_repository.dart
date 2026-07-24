import '../entities/meal_entity.dart';

abstract class MealRepository {
  /// Get all meals for a user on a given date (with items)
  Future<List<MealEntity>> getMealsByDate(String userId, DateTime date);

  /// Create or update a meal entry and return it with items
  Future<MealEntity> addMeal(MealEntity meal, List<Map<String, dynamic>> items);

  /// Update meal fields (e.g. notes)
  Future<void> updateMeal(String mealId, Map<String, dynamic> data);

  /// Delete an entire meal and its items
  Future<void> deleteMeal(String mealId);

  /// Add a food item to an existing meal (or create meal if not exists)
  /// Returns the updated meal
  Future<MealEntity> addFoodToMeal({
    required String userId,
    required String mealType,
    required String foodName,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required double servingSize,
    required String servingUnit,
    DateTime? date,
  });

  /// Remove a single meal item, auto-recalculate meal total calories
  Future<MealEntity> deleteMealItem(String itemId, String mealId);
}