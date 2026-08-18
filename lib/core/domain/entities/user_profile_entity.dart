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

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) {
    return UserProfileEntity(
      userId: json['user_id']?.toString() ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      age: _parseInt(json['age']),
      gender: json['gender'] as String?,
      heightCm: _parseDouble(json['height_cm']),
      weightKg: _parseDouble(json['weight_kg']),
      goalWeightKg: _parseDouble(json['goal_weight_kg']),
      activityLevel: json['activity_level'] as String?,
      goalType: json['goal_type'] as String?,
      dietPreference: json['diet_preference'] as String?,
      workoutFrequency: _parseInt(json['workout_frequency']),
      bio: json['bio'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
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