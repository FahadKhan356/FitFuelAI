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