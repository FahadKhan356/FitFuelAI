class MealModel {
  final String id;
  final String userId;
  final DateTime date;
  final String mealType;
  final int totalCalories;
  final String? notes;
  final DateTime? createdAt;
  final List<MealItemModel> items;

  const MealModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    this.totalCalories = 0,
    this.notes,
    this.createdAt,
    this.items = const [],
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      mealType: json['meal_type'] as String,
      totalCalories: (json['total_calories'] as int?) ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => MealItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T').first,
      'meal_type': mealType,
      'total_calories': totalCalories,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

class MealItemModel {
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

  const MealItemModel({
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

  factory MealItemModel.fromJson(Map<String, dynamic> json) {
    return MealItemModel(
      id: json['id'] as String,
      mealId: json['meal_id'] as String,
      foodName: json['food_name'] as String,
      calories: json['calories'] as int,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      servingSize: (json['serving_size'] as num?)?.toDouble() ?? 100,
      servingUnit: json['serving_unit'] as String? ?? 'g',
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meal_id': mealId,
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}