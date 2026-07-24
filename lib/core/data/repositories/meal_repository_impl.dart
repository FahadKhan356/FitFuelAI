import '../../domain/entities/meal_entity.dart';
import '../../domain/repositories/meal_repository.dart';
import '../datasources/supabase_remote_datasource.dart';
import '../models/meal_model.dart';

class MealRepositoryImpl implements MealRepository {
  final SupabaseRemoteDataSource _dataSource;

  MealRepositoryImpl(this._dataSource);

  @override
  Future<List<MealEntity>> getMealsByDate(String userId, DateTime date) async {
    final models = await _dataSource.getMealsByDate(userId, date);
    return models.map((m) => _toEntity(m)).toList();
  }

  @override
  Future<MealEntity> addMeal(MealEntity meal, List<Map<String, dynamic>> items) async {
    final mealData = {
      'user_id': meal.userId,
      'date': meal.date.toIso8601String().split('T').first,
      'meal_type': meal.mealType,
      'notes': meal.notes,
    };
    final createdMeal = await _dataSource.addMeal(mealData);
    
    for (final item in items) {
      await _dataSource.addMealItem({
        'meal_id': createdMeal.id,
        ...item,
      });
    }
    
    final meals = await _dataSource.getMealsByDate(meal.userId, meal.date);
    return _toEntity(meals.firstWhere((m) => m.id == createdMeal.id));
  }

  @override
  Future<void> updateMeal(String mealId, Map<String, dynamic> data) async {
    await _dataSource.updateMeal(mealId, data);
  }

  @override
  Future<void> deleteMeal(String mealId) async {
    await _dataSource.deleteMeal(mealId);
  }

  @override
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
  }) async {
    final today = date ?? DateTime.now();
    final dateStr = today.toIso8601String().split('T').first;

    // Check if a meal of this type already exists for this date
    final existingMeals = await _dataSource.getMealsByDate(userId, today);
    var meal = existingMeals.cast<MealModel?>().firstWhere(
      (m) => m!.mealType == mealType,
      orElse: () => null,
    );

    // Create the meal if it doesn't exist
    if (meal == null) {
      final newMeal = await _dataSource.addMeal({
        'user_id': userId,
        'date': dateStr,
        'meal_type': mealType,
        'total_calories': 0,
      });
      meal = newMeal;
    }

    // Insert the meal item
    await _dataSource.addMealItem({
      'meal_id': meal.id,
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
    });

    // Recalculate total calories for the meal
    // Re-fetch to get all items with their new item included
    final updatedMealData = await _dataSource.getMealById(meal.id);
    if (updatedMealData == null) {
      return _toEntity(meal);
    }

    final updatedMeal = MealModel.fromJson(updatedMealData);
    final newTotal = updatedMeal.items.fold<int>(0, (sum, item) => sum + item.calories);
    
    await _dataSource.updateMeal(meal.id, {'total_calories': newTotal});

    // Re-fetch final state
    final finalMealData = await _dataSource.getMealById(meal.id);
    if (finalMealData == null) {
      // Return what we have
      return _toEntity(MealModel(
        id: meal.id,
        userId: meal.userId,
        date: meal.date,
        mealType: meal.mealType,
        totalCalories: newTotal,
        items: updatedMeal.items,
      ));
    }
    return _toEntity(MealModel.fromJson(finalMealData));
  }

  @override
  Future<MealEntity> deleteMealItem(String itemId, String mealId) async {
    // Delete the item
    await _dataSource.deleteMealItem(itemId);

    // Re-fetch meal to recalculate
    final mealData = await _dataSource.getMealById(mealId);
    if (mealData == null) {
      throw Exception('Meal not found after item deletion');
    }

    final meal = MealModel.fromJson(mealData);
    final newTotal = meal.items.fold<int>(0, (sum, item) => sum + item.calories);
    
    await _dataSource.updateMeal(mealId, {'total_calories': newTotal});

    // Re-fetch final state
    final finalMealData = await _dataSource.getMealById(mealId);
    return _toEntity(MealModel.fromJson(finalMealData!));
  }

  MealEntity _toEntity(MealModel model) {
    return MealEntity(
      id: model.id,
      userId: model.userId,
      date: model.date,
      mealType: model.mealType,
      totalCalories: model.totalCalories,
      notes: model.notes,
      createdAt: model.createdAt,
      items: model.items.map((i) => MealItemEntity(
        id: i.id,
        mealId: i.mealId,
        foodName: i.foodName,
        calories: i.calories,
        protein: i.protein,
        carbs: i.carbs,
        fat: i.fat,
        fiber: i.fiber,
        servingSize: i.servingSize,
        servingUnit: i.servingUnit,
        photoUrl: i.photoUrl,
        createdAt: i.createdAt,
      )).toList(),
    );
  }
}