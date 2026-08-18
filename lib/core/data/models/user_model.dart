/// Unified user model combining auth, profile, and goals data.
///
/// Maps to Supabase tables `user_profiles` and `goals`.
class UserModel {
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;

  // ── user_profiles columns ──
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? activityLevel;
  final String? dietPreference;
  final int? workoutFrequency;

  // ── goals columns ──
  final String? goalType;
  final double? targetWeightKg;
  final double? weeklyPaceKg;
  final DateTime? targetDate;
  final int? targetCalories;
  final double? targetProtein;
  final double? targetCarbs;
  final double? targetFat;
  final int? dailyWaterMl;

  const UserModel({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.dietPreference,
    this.workoutFrequency,
    this.goalType,
    this.targetWeightKg,
    this.weeklyPaceKg,
    this.targetDate,
    this.targetCalories,
    this.targetProtein,
    this.targetCarbs,
    this.targetFat,
    this.dailyWaterMl,
  });

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    return null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Support both flat unified maps and nested {profile, goals} maps.
    final profile = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : json;
    final goals = json['goals'] is Map<String, dynamic>
        ? json['goals'] as Map<String, dynamic>
        : json;

    return UserModel(
      id: json['id']?.toString() ?? profile['user_id']?.toString() ?? json['user_id']?.toString() ?? '',
      email: json['email'] as String?,
      name: profile['name'] as String? ?? json['name'] as String?,
      avatarUrl: profile['avatar_url'] as String? ?? json['avatar_url'] as String?,
      age: _parseInt(profile['age']) ?? _parseInt(json['age']),
      gender: profile['gender'] as String? ?? json['gender'] as String?,
      heightCm: _parseDouble(profile['height_cm']) ?? _parseDouble(json['height_cm']),
      weightKg: _parseDouble(profile['weight_kg']) ?? _parseDouble(json['weight_kg']),
      activityLevel: profile['activity_level'] as String? ?? json['activity_level'] as String?,
      dietPreference: profile['diet_preference'] as String? ?? json['diet_preference'] as String?,
      workoutFrequency: _parseInt(profile['workout_frequency']) ?? _parseInt(json['workout_frequency']),
      goalType: goals['goal_type'] as String? ?? json['goal_type'] as String?,
      targetWeightKg: _parseDouble(goals['target_weight_kg']) ?? _parseDouble(json['target_weight_kg']),
      weeklyPaceKg: _parseDouble(goals['weekly_pace_kg']) ?? _parseDouble(json['weekly_pace_kg']),
      targetDate: goals['target_date'] != null
          ? DateTime.tryParse(goals['target_date'] as String)
          : json['target_date'] != null
              ? DateTime.tryParse(json['target_date'] as String)
              : null,
      targetCalories: _parseInt(goals['target_calories']) ?? _parseInt(json['target_calories']),
      targetProtein: _parseDouble(goals['target_protein']) ?? _parseDouble(json['target_protein']),
      targetCarbs: _parseDouble(goals['target_carbs']) ?? _parseDouble(json['target_carbs']),
      targetFat: _parseDouble(goals['target_fat']) ?? _parseDouble(json['target_fat']),
      dailyWaterMl: _parseInt(goals['daily_water_ml']) ?? _parseInt(json['daily_water_ml']),
    );
  }

  /// Map for the `user_profiles` Supabase table (Upsert).
  Map<String, dynamic> toProfileJson() {
    return {
      'user_id': id,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (targetWeightKg != null) 'goal_weight_kg': targetWeightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (goalType != null) 'goal_type': goalType,
      if (dietPreference != null) 'diet_preference': dietPreference,
      if (workoutFrequency != null) 'workout_frequency': workoutFrequency,
    };
  }


  /// Map for the `goals` Supabase table (Upsert).
  Map<String, dynamic> toGoalsJson() {
    return {
      'user_id': id,
      if (goalType != null) 'goal_type': goalType,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (weeklyPaceKg != null) 'weekly_pace_kg': weeklyPaceKg,
      if (targetDate != null) 'target_date': targetDate!.toIso8601String().split('T').first,
      if (targetCalories != null) 'target_calories': targetCalories,
      if (targetProtein != null) 'target_protein': targetProtein,
      if (targetCarbs != null) 'target_carbs': targetCarbs,
      if (targetFat != null) 'target_fat': targetFat,
      if (dailyWaterMl != null) 'daily_water_ml': dailyWaterMl,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? dietPreference,
    int? workoutFrequency,
    String? goalType,
    double? targetWeightKg,
    double? weeklyPaceKg,
    DateTime? targetDate,
    int? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    int? dailyWaterMl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      dietPreference: dietPreference ?? this.dietPreference,
      workoutFrequency: workoutFrequency ?? this.workoutFrequency,
      goalType: goalType ?? this.goalType,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      weeklyPaceKg: weeklyPaceKg ?? this.weeklyPaceKg,
      targetDate: targetDate ?? this.targetDate,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      dailyWaterMl: dailyWaterMl ?? this.dailyWaterMl,
    );
  }
}