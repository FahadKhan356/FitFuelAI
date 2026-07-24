class MealEntity {
  final String id;
  final String userId;
  final DateTime date;
  final String mealType;
  final int totalCalories;
  final String? notes;
  final DateTime? createdAt;
  final List<MealItemEntity> items;

  const MealEntity({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    this.totalCalories = 0,
    this.notes,
    this.createdAt,
    this.items = const [],
  });
}

class MealItemEntity {
  final String id;
  final String mealId;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double servingSize;
  final String servingUnit;
  final String? photoUrl;
  final DateTime? createdAt;

  const MealItemEntity({
    required this.id,
    required this.mealId,
    required this.foodName,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.servingSize = 100,
    this.servingUnit = 'g',
    this.photoUrl,
    this.createdAt,
  });
}