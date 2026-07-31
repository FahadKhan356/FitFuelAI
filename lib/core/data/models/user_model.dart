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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Support both flat unified maps and nested {profile, goals} maps.
    final profile = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : json;
    final goals = json['goals'] is Map<String, dynamic>
        ? json['goals'] as Map<String, dynamic>
        : json;

    return UserModel(
      id: json['id'] as String? ?? profile['user_id'] as String? ?? json['user_id'] as String? ?? '',
      email: json['email'] as String?,
      name: profile['name'] as String? ?? json['name'] as String?,
      avatarUrl: profile['avatar_url'] as String? ?? json['avatar_url'] as String?,
      age: profile['age'] as int? ?? json['age'] as int?,
      gender: profile['gender'] as String? ?? json['gender'] as String?,
      heightCm: (profile['height_cm'] as num?)?.toDouble() ?? (json['height_cm'] as num?)?.toDouble(),
      weightKg: (profile['weight_kg'] as num?)?.toDouble() ?? (json['weight_kg'] as num?)?.toDouble(),
      activityLevel: profile['activity_level'] as String? ?? json['activity_level'] as String?,
      dietPreference: profile['diet_preference'] as String? ?? json['diet_preference'] as String?,
      workoutFrequency: profile['workout_frequency'] as int? ?? json['workout_frequency'] as int?,
      goalType: goals['goal_type'] as String? ?? json['goal_type'] as String?,
      targetWeightKg: (goals['target_weight_kg'] as num?)?.toDouble() ?? (json['target_weight_kg'] as num?)?.toDouble(),
      weeklyPaceKg: (goals['weekly_pace_kg'] as num?)?.toDouble() ?? (json['weekly_pace_kg'] as num?)?.toDouble(),
      targetDate: goals['target_date'] != null
          ? DateTime.tryParse(goals['target_date'] as String)
          : json['target_date'] != null
              ? DateTime.tryParse(json['target_date'] as String)
              : null,
      targetCalories: (goals['target_calories'] as num?)?.toInt() ?? (json['target_calories'] as num?)?.toInt(),
      targetProtein: (goals['target_protein'] as num?)?.toDouble() ?? (json['target_protein'] as num?)?.toDouble(),
      targetCarbs: (goals['target_carbs'] as num?)?.toDouble() ?? (json['target_carbs'] as num?)?.toDouble(),
      targetFat: (goals['target_fat'] as num?)?.toDouble() ?? (json['target_fat'] as num?)?.toDouble(),
      dailyWaterMl: (goals['daily_water_ml'] as num?)?.toInt() ?? (json['daily_water_ml'] as num?)?.toInt(),
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
      if (activityLevel != null) 'activity_level': activityLevel,
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