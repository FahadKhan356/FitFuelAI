class GoalEntity {
  final String id;
  final String userId;
  final int targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final int dailyWaterMl;
  final String? goalType;
  final double? targetWeightKg;
  final double? weeklyPaceKg;
  final DateTime? targetDate;
  final DateTime? updatedAt;

  const GoalEntity({
    required this.id,
    required this.userId,
    this.targetCalories = 0, // Will be set dynamically from calculations
    this.targetProtein = 0,
    this.targetCarbs = 0,
    this.targetFat = 0,
    this.dailyWaterMl = 0,
    this.goalType,
    this.targetWeightKg,
    this.weeklyPaceKg,
    this.targetDate,
    this.updatedAt,
  });

  factory GoalEntity.fromJson(Map<String, dynamic> json) => GoalEntity(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    targetCalories: (json['target_calories'] as num?)?.toInt() ?? 0,
    targetProtein: (json['target_protein'] as num?)?.toDouble() ?? 0,
    targetCarbs: (json['target_carbs'] as num?)?.toDouble() ?? 0,
    targetFat: (json['target_fat'] as num?)?.toDouble() ?? 0,
    dailyWaterMl: (json['daily_water_ml'] as num?)?.toInt() ?? 0,
    goalType: json['goal_type'] as String?,
    targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
    weeklyPaceKg: (json['weekly_pace_kg'] as num?)?.toDouble(),
    targetDate: json['target_date'] != null
        ? DateTime.tryParse(json['target_date'] as String)
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'goal_type': goalType,
      'target_weight_kg': targetWeightKg,
      'weekly_pace_kg': weeklyPaceKg,
      if (targetDate != null)
        'target_date': targetDate!.toIso8601String().split('T').first,
      'target_calories': targetCalories,
      'target_protein': targetProtein,
      'target_carbs': targetCarbs,
      'target_fat': targetFat,
      'daily_water_ml': dailyWaterMl,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  GoalEntity copyWith({
    String? id,
    String? userId,
    int? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    int? dailyWaterMl,
    String? goalType,
    double? targetWeightKg,
    double? weeklyPaceKg,
    DateTime? targetDate,
    DateTime? updatedAt,
  }) {
    return GoalEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      dailyWaterMl: dailyWaterMl ?? this.dailyWaterMl,
      goalType: goalType ?? this.goalType,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      weeklyPaceKg: weeklyPaceKg ?? this.weeklyPaceKg,
      targetDate: targetDate ?? this.targetDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}