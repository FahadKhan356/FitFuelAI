/// Combines user_profiles + goals table data into one model for the profile feature.
class UserProfileModel {
  final String userId;
  final String? name;
  final String? avatarUrl;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final String? activityLevel;
  final String? goalType;
  final String? bio;
  final DateTime? createdAt;

  // Goals fields
  final int targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final int dailyWaterMl;

  const UserProfileModel({
    required this.userId,
    this.name,
    this.avatarUrl,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.goalWeightKg,
    this.activityLevel,
    this.goalType,
    this.bio,
    this.createdAt,
    this.targetCalories = 2000,
    this.targetProtein = 150,
    this.targetCarbs = 200,
    this.targetFat = 65,
    this.dailyWaterMl = 2500,
  });

  /// Convert profile fields to map for user_profiles table
  Map<String, dynamic> toProfileJson() => {
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (heightCm != null) 'height_cm': heightCm,
        if (weightKg != null) 'weight_kg': weightKg,
        if (goalWeightKg != null) 'goal_weight_kg': goalWeightKg,
        if (activityLevel != null) 'activity_level': activityLevel,
        if (goalType != null) 'goal_type': goalType,
        if (bio != null) 'bio': bio,
      };

  /// Convert goals fields to map for goals table
  Map<String, dynamic> toGoalsJson() => {
        'target_calories': targetCalories,
        'target_protein': targetProtein,
        'target_carbs': targetCarbs,
        'target_fat': targetFat,
        'daily_water_ml': dailyWaterMl,
        if (goalType != null) 'goal_type': goalType,
      };

  /// Create a new model with updated fields (immutable)
  UserProfileModel copyWith({
    String? userId,
    String? name,
    String? avatarUrl,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    String? activityLevel,
    String? goalType,
    String? bio,
    DateTime? createdAt,
    int? targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    int? dailyWaterMl,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      dailyWaterMl: dailyWaterMl ?? this.dailyWaterMl,
    );
  }

  /// Calculate BMI from height and weight
  double? get bmi {
    if (heightCm == null || weightKg == null || heightCm! <= 0) return null;
    final heightM = heightCm! / 100;
    return double.parse((weightKg! / (heightM * heightM)).toStringAsFixed(1));
  }
}