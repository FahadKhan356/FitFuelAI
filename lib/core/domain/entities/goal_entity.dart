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

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  factory GoalEntity.fromJson(Map<String, dynamic> json) => GoalEntity(
    id: json['id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    targetCalories: _parseInt(json['target_calories']),
    targetProtein: _parseDouble(json['target_protein']),
    targetCarbs: _parseDouble(json['target_carbs']),
    targetFat: _parseDouble(json['target_fat']),
    dailyWaterMl: _parseInt(json['daily_water_ml']),
    goalType: json['goal_type'] as String?,
    targetWeightKg: json['target_weight_kg'] != null ? _parseDouble(json['target_weight_kg']) : null,
    weeklyPaceKg: json['weekly_pace_kg'] != null ? _parseDouble(json['weekly_pace_kg']) : null,
    targetDate: json['target_date'] != null
        ? DateTime.tryParse(json['target_date'].toString())
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
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