class UserProfileEntity {
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
  final String? dietPreference;
  final int? workoutFrequency;
  final String? bio;
  final DateTime? createdAt;

  const UserProfileEntity({
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
    this.dietPreference,
    this.workoutFrequency,
    this.bio,
    this.createdAt,
  });

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) {
    return UserProfileEntity(
      userId: json['user_id'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      goalWeightKg: (json['goal_weight_kg'] as num?)?.toDouble(),
      activityLevel: json['activity_level'] as String?,
      goalType: json['goal_type'] as String?,
      dietPreference: json['diet_preference'] as String?,
      workoutFrequency: json['workout_frequency'] as int?,
      bio: json['bio'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (goalWeightKg != null) 'goal_weight_kg': goalWeightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (goalType != null) 'goal_type': goalType,
      if (dietPreference != null) 'diet_preference': dietPreference,
      if (workoutFrequency != null) 'workout_frequency': workoutFrequency,
      if (bio != null) 'bio': bio,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  UserProfileEntity copyWith({
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
    String? dietPreference,
    int? workoutFrequency,
    String? bio,
    DateTime? createdAt,
  }) {
    return UserProfileEntity(
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
      dietPreference: dietPreference ?? this.dietPreference,
      workoutFrequency: workoutFrequency ?? this.workoutFrequency,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}